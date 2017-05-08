defmodule Pay.PageTestView do
  use Pay.Web, :view

  def render("index.json", %{data: return_data}) do
    return_data
  end
end
