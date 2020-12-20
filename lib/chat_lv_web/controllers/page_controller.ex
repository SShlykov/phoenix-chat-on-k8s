defmodule ChatLvWeb.PageController do
  use ChatLvWeb, :controller

  def index(conn, _params) do
    nodes = inspect(Node.list([:this, :visible]))
    node  = node()
    render(conn, "index.html", %{nodes: nodes, node: node})
  end
end
