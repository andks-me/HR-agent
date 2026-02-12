defmodule HrBrandAgent.Storage.Cloud do
  @moduledoc """
  Cloud storage integration using AWS S3.
  """
  require Logger

  @doc """
  Upload a file to S3.
  """
  def upload_file(local_path, remote_path, opts \\ []) do
    bucket = Application.get_env(:ex_aws, :s3)[:bucket]
    
    unless bucket do
      Logger.warning("S3 bucket not configured, skipping cloud upload")
      {:ok, :skipped}
    end
    
    # Read file
    case File.read(local_path) do
      {:ok, content} ->
        # Determine content type
        content_type = opts[:content_type] || guess_content_type(local_path)
        
        # Upload to S3
        result = ExAws.S3.put_object(bucket, remote_path, content, [
          content_type: content_type,
          acl: :private
        ])
        |> ExAws.request()
        
        case result do
          {:ok, _} ->
            Logger.info("File uploaded to S3: #{remote_path}")
            {:ok, "s3://#{bucket}/#{remote_path}"}
            
          {:error, error} ->
            Logger.error("Failed to upload to S3: #{inspect(error)}")
            {:error, error}
        end
        
      {:error, reason} ->
        {:error, reason}
    end
  end

  @doc """
  Download a file from S3.
  """
  def download_file(remote_path, local_path) do
    bucket = Application.get_env(:ex_aws, :s3)[:bucket]
    
    unless bucket do
      {:error, :not_configured}
    end
    
    result = ExAws.S3.get_object(bucket, remote_path)
    |> ExAws.request()
    
    case result do
      {:ok, %{body: content}} ->
        File.write!(local_path, content)
        {:ok, local_path}
        
      {:error, error} ->
        {:error, error}
    end
  end

  @doc """
  Generate a presigned URL for temporary access.
  """
  def presigned_url(remote_path, expires_in \\ 3600) do
    bucket = Application.get_env(:ex_aws, :s3)[:bucket]
    
    unless bucket do
      {:error, :not_configured}
    end
    
    # Generate presigned URL
    url = ExAws.S3.presigned_url(
      ExAws.Config.new(:s3),
      :get,
      bucket,
      remote_path,
      expires_in: expires_in
    )
    
    {:ok, url}
  end

  @doc """
  List files in S3 with given prefix.
  """
  def list_files(prefix \\ "") do
    bucket = Application.get_env(:ex_aws, :s3)[:bucket]
    
    unless bucket do
      {:ok, []}
    end
    
    result = ExAws.S3.list_objects(bucket, prefix: prefix)
    |> ExAws.request()
    
    case result do
      {:ok, %{body: %{contents: contents}}} ->
        files = Enum.map(contents, fn obj ->
          %{
            key: obj.key,
            size: obj.size,
            last_modified: obj.last_modified
          }
        end)
        
        {:ok, files}
        
      {:error, error} ->
        {:error, error}
    end
  end

  @doc """
  Delete a file from S3.
  """
  def delete_file(remote_path) do
    bucket = Application.get_env(:ex_aws, :s3)[:bucket]
    
    unless bucket do
      {:ok, :skipped}
    end
    
    ExAws.S3.delete_object(bucket, remote_path)
    |> ExAws.request()
  end

  # Private functions
  defp guess_content_type(path) do
    ext = Path.extname(path) |> String.downcase()
    
    case ext do
      ".html" -> "text/html"
      ".pdf" -> "application/pdf"
      ".csv" -> "text/csv"
      ".json" -> "application/json"
      ".png" -> "image/png"
      ".jpg" -> "image/jpeg"
      ".jpeg" -> "image/jpeg"
      _ -> "application/octet-stream"
    end
  end
end
