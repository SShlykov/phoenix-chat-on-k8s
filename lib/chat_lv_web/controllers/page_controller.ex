defmodule ChatLvWeb.PageController do
  use ChatLvWeb, :controller

  def index(conn, _params) do
    nodes = inspect(Node.list([:this, :visible]))
    node  = node()
    repo_test_result = inspect(ChatLv.Repo.query("Select 1 as test"))
    render(conn, "index.html", %{nodes: nodes, node: node, repo_test_result: repo_test_result})
  end
end
