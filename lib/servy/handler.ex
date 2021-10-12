defmodule Servy.Handler do

  @moduledoc """
  Handles HTTP requests.
  """
  alias Servy.Conv
  alias Servy.BearController
  alias Servy.VideoCam

  @pages_path Path.expand("../../pages/", __DIR__)

  import Servy.Plugins, only: [rewrite_path: 1, log: 1, track: 1]
  import Servy.Parser, only: [parse: 1]

  @doc """
  Transforms the request into a response
  """
  def handle(request) do
    request
    |> parse
    |> rewrite_path
    |> log
    |> route
    |> track
    |> format_response
  end


  def route(%Conv{ method: "GET", path: "/wildthings" } = conv) do
    %{ conv | resp_body: "Bears, Lions, Tigers", status: 200 }
  end

  def route(%Conv{ method: "GET", path: "/about" } = conv) do
    @pages_path
    |> Path.join("about.html")
    |> File.read
    |> handle_file(conv)
  end

  def handle_file({:ok, content}, conv) do
    %{ conv | resp_body: content, status: 200 }
  end

  def handle_file({:error, :enoent}, conv) do
    %{ conv | resp_body: "File not found", status: 404 }
  end

  def handle_file({:error, reason}, conv) do
    %{ conv | resp_body: "File error: #{reason}", status: 500 }
  end

  def route(%Conv{method: "POST", path: "/pledges"} = conv) do
    Servy.PledgeController.create(conv, conv.params)
  end

  def route(%Conv{method: "GET", path: "/pledges"} = conv) do
    Servy.PledgeController.index(conv)
  end

  def route(%Conv{ method: "GET", path: "/bears/new" } = conv) do
    file =
      @pages_path
      |> Path.join("form.html")

    case File.read(file) do
      {:ok, content} ->
        %{ conv | resp_body: content, status: 200 }
      {:error, :enoent} ->
        %{ conv | resp_body: "File not found", status: 500 }
      {:error, reason} ->
        %{ conv | resp_body: "File error: #{reason}", status: 500 }
    end
  end

  def route(%Conv{ method: "GET", path: "/bears" } = conv) do
    BearController.index(conv)
  end

  def route(%Conv{ method: "GET", path: "/api/bears" } = conv) do
    Servy.Api.BearController.index(conv)
  end

  def route(%Conv{ method: "GET", path: "/bears/" <> id} = conv) do
    params = Map.put(conv.params, "id", id)
    BearController.show(conv, params)
  end

  def route(%Conv{ method: "DELETE", path: "/bears/" <> id} = conv) do
    params = Map.put(conv.params, "id", id)
    BearController.delete(conv, params)
  end

  def route(%Conv{method: "POST", path: "/bears"} = conv) do
    BearController.create(conv, conv.params)
  end

  def route(%Conv{ method: "GET", path: "/hibernate/" <> time } = conv) do
    time |> String.to_integer |> :timer.sleep

    %{ conv | status: 200, resp_body: "Awake!" }
  end

  def route(%Conv{ method: "GET", path: "/kaboom" } = conv) do
    raise "Kaboom!"
  end

  def route(%Conv{ method: "GET", path: "/sensors" } = conv) do
    sensor_data = Servy.SensorServer.get_sensor_data()
    %{ conv | status: 200, resp_body: inspect sensor_data}
  end

  def route(%Conv{ path: path } = conv) do
    %{ conv | resp_body: "No #{path} here!", status: 404 }
  end

  def format_response(%Conv{} = conv) do
    """
    HTTP/1.1 #{Conv.full_status(conv)}\r
    Content-Type: #{conv.resp_content_type}\r
    Content-Length: #{byte_size(conv.resp_body)}\r
    \r
    #{conv.resp_body}
    """
  end
end
