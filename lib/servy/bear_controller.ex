defmodule Servy.BearController do
  alias Servy.Wildthings
  alias Servy.Bear
  @templates_path Path.expand("../../templates/", __DIR__)
  defp bear_item(bear) do
    "<li>#{bear.name} - #{bear.type}"
  end

  defp render(conv, template, bindings \\ []) do
    content =
    @templates_path
    |> Path.join(template)
    |> EEx.eval_file(bindings)

    %{ conv | resp_body: content, status: 200 }
  end

  def index(conv) do
    bears =
      Wildthings.list_bears()
      |> Enum.sort(&Bear.sort/2)

    render(conv, "index.eex", bears: bears)
  end

  def show(conv, %{"id" => id}) do
    bear = Wildthings.get_bear(id)

    render(conv, "show.eex", bear: bear)
  end

  def create(conv, %{"name" => name, "type" => type} = params) do
    %{ conv | status: 201,
              resp_body: "Created a #{type} bear named #{name}!" }
  end

  def delete(conv, %{"id" => id}) do
    bear = Wildthings.get_bear(id)
    %{ conv | resp_body: "Bear #{bear.name} deleted", status: 200 }
  end
end
