defmodule HrBrandAgent.Integrations.LinkedIn.Browser do
  @moduledoc """
  LinkedIn browser automation using Hound (Selenium WebDriver).
  Handles automated login and data extraction.
  """
  use GenServer
  require Logger

  @linkedin_login_url "https://www.linkedin.com/login"
  @linkedin_home_url "https://www.linkedin.com/feed/"

  # Client API
  def start_link(opts) do
    GenServer.start_link(__MODULE__, opts, name: __MODULE__)
  end

  def login(email, password) do
    GenServer.call(__MODULE__, {:login, email, password}, 60_000)
  end

  def research_company(company_name, company_url) do
    GenServer.call(__MODULE__, {:research_company, company_name, company_url}, 120_000)
  end

  def get_job_descriptions(company_name) do
    GenServer.call(__MODULE__, {:get_jobs, company_name}, 60_000)
  end

  def close_session do
    GenServer.call(__MODULE__, :close_session)
  end

  # Server callbacks
  @impl true
  def init(_opts) do
    # Initialize Hound
    Application.put_env(:hound, :driver, "chrome_driver")
    Application.put_env(:hound, :browser, "chrome_headless")
    
    {:ok, %{session: nil, logged_in: false}}
  end

  @impl true
  def handle_call({:login, email, password}, _from, state) do
    try do
      # Start new browser session
      session = Hound.start_session()
      
      # Navigate to login page
      Hound.navigate_to(@linkedin_login_url)
      
      # Wait for page to load
      :timer.sleep(2000)
      
      # Fill in email
      email_field = Hound.find_element(:id, "username")
      Hound.fill_field(email_field, email)
      
      # Fill in password
      password_field = Hound.find_element(:id, "password")
      Hound.fill_field(password_field, password)
      
      # Click login button
      login_button = Hound.find_element(:css, "button[type='submit']")
      Hound.click(login_button)
      
      # Wait for login to complete
      :timer.sleep(5000)
      
      # Check if login was successful
      current_url = Hound.current_url()
      
      if String.contains?(current_url, "linkedin.com/feed") or 
         String.contains?(current_url, "linkedin.com/in/") do
        Logger.info("LinkedIn login successful")
        {:reply, :ok, %{state | session: session, logged_in: true}}
      else
        Logger.error("LinkedIn login failed")
        Hound.end_session(session)
        {:reply, {:error, :login_failed}, %{state | session: nil, logged_in: false}}
      end
    rescue
      error ->
        Logger.error("LinkedIn login error: #{inspect(error)}")
        {:reply, {:error, error}, state}
    end
  end

  @impl true
  def handle_call({:research_company, company_name, company_url}, _from, %{logged_in: true, session: session} = state) do
    try do
      # Navigate to company page
      company_page = company_url || "https://www.linkedin.com/company/#{String.downcase(company_name)}/"
      Hound.navigate_to(company_page)
      
      :timer.sleep(3000)
      
      # Extract company information
      company_info = %{
        name: company_name,
        url: company_page,
        description: extract_description(session),
        employee_count: extract_employee_count(session),
        industry: extract_industry(session),
        headquarters: extract_headquarters(session),
        founded: extract_founded(session),
        specialties: extract_specialties(session)
      }
      
      {:reply, {:ok, company_info}, state}
    rescue
      error ->
        Logger.error("LinkedIn company research error: #{inspect(error)}")
        {:reply, {:error, error}, state}
    end
  end

  @impl true
  def handle_call({:get_jobs, company_name}, _from, %{logged_in: true, session: session} = state) do
    try do
      # Navigate to company jobs page
      jobs_url = "https://www.linkedin.com/jobs/search/?f_C=#{URI.encode(company_name)}&geoId=92000000"
      Hound.navigate_to(jobs_url)
      
      :timer.sleep(3000)
      
      # Extract job listings
      jobs = extract_job_listings(session)
      
      {:reply, {:ok, jobs}, state}
    rescue
      error ->
        Logger.error("LinkedIn jobs extraction error: #{inspect(error)}")
        {:reply, {:error, error}, state}
    end
  end

  @impl true
  def handle_call(:close_session, _from, %{session: session} = state) when not is_nil(session) do
    try do
      Hound.end_session(session)
      {:reply, :ok, %{state | session: nil, logged_in: false}}
    rescue
      _ -> {:reply, :ok, %{state | session: nil, logged_in: false}}
    end
  end

  @impl true
  def handle_call(:close_session, _from, state) do
    {:reply, :ok, state}
  end

  # Private helper functions
  defp extract_description(session) do
    try do
      element = Hound.find_element(:css, ".organization-about__description")
      Hound.visible_text(element)
    rescue
      _ -> nil
    end
  end

  defp extract_employee_count(session) do
    try do
      element = Hound.find_element(:css, ".org-top-card-summary-info-list__info-item")
      text = Hound.visible_text(element)
      
      # Extract number from text like "10,001+ employees"
      case Regex.run(~r/([\d,]+)\+?\s*employees?/, text) do
        [_, count] -> String.replace(count, ",", "")
        _ -> text
      end
    rescue
      _ -> nil
    end
  end

  defp extract_industry(session) do
    try do
      elements = Hound.find_all_elements(:css, ".org-top-card-summary-info-list__info-item")
      
      Enum.find_value(elements, fn el ->
        text = Hound.visible_text(el)
        if String.contains?(text, "employees"), do: nil, else: text
      end)
    rescue
      _ -> nil
    end
  end

  defp extract_headquarters(_session) do
    # Would need to navigate to company about page
    nil
  end

  defp extract_founded(_session) do
    # Would need to navigate to company about page
    nil
  end

  defp extract_specialties(_session) do
    # Would need to navigate to company about page
    nil
  end

  defp extract_job_listings(session) do
    try do
      job_cards = Hound.find_all_elements(:css, ".job-card-container")
      
      Enum.map(job_cards, fn card ->
        try do
          title_el = Hound.find_within_element(card, :css, ".job-card-list__title")
          company_el = Hound.find_within_element(card, :css, ".job-card-container__company-name")
          location_el = Hound.find_within_element(card, :css, ".job-card-container__metadata-item")
          
          %{
            title: Hound.visible_text(title_el),
            company: Hound.visible_text(company_el),
            location: Hound.visible_text(location_el),
            url: Hound.attribute_value(title_el, "href")
          }
        rescue
          _ -> nil
        end
      end)
      |> Enum.reject(&is_nil/1)
      |> Enum.take(20)  # Limit to 20 jobs
    rescue
      _ -> []
    end
  end
end
