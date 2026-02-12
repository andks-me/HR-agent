defmodule Mix.Tasks.Export do
  @moduledoc """
  CLI task to export research results.

  ## Examples

      mix export --session 123 --format html
      mix export --session 123 --format pdf
      mix export --session 123 --format csv
  """

  use Mix.Task

  alias HrBrandAgent.Exports.Generator

  @shortdoc "Export research results"

  @impl Mix.Task
  def run(args) do
    # Start the application
    Mix.Task.run("app.start")

    # Parse arguments
    {opts, _, _} = OptionParser.parse(args,
      switches: [
        session: :integer,
        format: :string,
        output: :string
      ],
      aliases: [
        s: :session,
        f: :format
      ]
    )

    session_id = opts[:session] || raise "--session is required"
    format = opts[:format] || "html"
    output_dir = opts[:output] || File.cwd!()

    Mix.shell().info("Exporting research session #{session_id} as #{format}...")

    result = case format do
      "html" ->
        Generator.generate_html(session_id)
        
      "pdf" ->
        Generator.generate_pdf(session_id)
        
      "csv" ->
        Generator.generate_csv(session_id)
        
      _ ->
        Mix.shell().error("Unknown format: #{format}")
        System.halt(1)
    end

    case result do
      {:ok, path} ->
        Mix.shell().info("✓ Export complete!")
        Mix.shell().info("File saved to: #{path}")
        
      {:error, error} ->
        Mix.shell().error("Export failed: #{inspect(error)}")
        System.halt(1)
    end
  end
end
