**Заранее, в контроллере, обратимся к спику подключенных в общую сеть экземпляров приложений и передадим их в шаблон вместе с именем текушего экземпляра**
```elixir
#--> lib/chat_lv_web/controllers/page_controller.ex
def index(conn, _params) do
    nodes = inspect(Node.list([:this, :visible]))
    node = node()
    repo_test_result = inspect(ChatLv.Repo.query("Select 1 as test"))
    render(conn, "index.html", %{nodes: nodes, node: node, repo_test_result: repo_test_result})
end
```
**Создадим шаблон страницы и общую тему**

```html
#--> lib/chat_lv_web/templates/layout/root.html.leex
#--> вместо head
<link rel="stylesheet" href="https://maxcdn.bootstrapcdn.com/bootstrap/3.3.7/css/bootstrap.min.css" integrity="sha384-BVYiiSIFeK1dGmJRAkycuHAHRg32OmUcww7on3RYdg4Va+PmSTsz/K68vbdEjh4u" crossorigin="anonymous">
#--> вместо header
<div class="navbar navbar-default navbar-fixed-top" role="navigation">
    <div class="container d-flex justify-content-center align-items-center ">
        <a class="navbar-brand" href="#">Phoenix Chat</a>
        <div style="padding: 13px; display: flex; flex-direction: column;">
          <span style="color: gray; font-size: 10px">self:  <span style="color: green;"> <%= @node %></span></span>
          <span style="color: gray; font-size: 10px">nodes: <span style="color: red;"> <%= @nodes %></span></span>
          <span style="color: gray; font-size: 10px">repo_test: <span style="color: gray;"> <%= @repo_test_result %></span></span>
        </div>
    </div>
    </div>
</div>
#--> подставить footer
<div id="footer">
<div class="container">
    <div class="row">
    <div class="col-sm-2">
        <div class="input-group">
        <span class="input-group-addon">@</span>
        <input id="username" type="text" class="form-control" placeholder="username">
        </div><!-- /input-group -->
    </div><!-- /.col-lg-6 -->
    <div class="col-sm-10">
        <input id="message-input" class="form-control" />
    </div><!-- /.col-lg-6 -->
    </div><!-- /.row -->
</div>
</div>
<script src="https://ajax.googleapis.com/ajax/libs/jquery/1.12.4/jquery.min.js"></script>
#--> lib/chat_lv_web/templates/page/index.html.eex
<div class="messages-container" id="messages-container">
    <div id="messages" class="container">

    </div>
</div>

```

**Добавим стили**
```css
#--> assets/css/app.scss


#footer {
  position: fixed;
  bottom: 0px;
  width: 100%;
  height: 60px;
  padding-top: 1em;
  background-color: #f5f5f5;
}
body > .container {
  padding: 50px 15px 0;
  height: 100vh;
}
.container .text-muted {
  margin: 20px 0;
}

#footer > .container {
  padding-right: 15px;
  padding-left: 15px;
}
#footer{
  position: absolute;
  bottom: 0;
  width: 100%;
  background-color: white;
  overflow: hidden;
}
.messages-container{
  height: calc(90vh - 50px);
  overflow-x: hidden;
  overflow-y: auto;
}
code {
  font-size: 80%;
}

```

**Логика подключения к комнате и обмен сообщениями, создаем новый канал**
```elixir
#--> lib/chat_lv_web/channels/room_channel.ex
defmodule ChatLvWeb.RoomChannel do
  use Phoenix.Channel
  require Logger
  def join("rooms:lobby", message, socket) do
    Process.flag(:trap_exit, true)
    :timer.send_interval(5000, :ping)
    send(self(), {:after_join, message})

    {:ok, socket}
  end

  def join("rooms:" <> _private_subtopic, _message, _socket) do
    {:error, %{reason: "unauthorized"}}
  end

  def handle_info({:after_join, msg}, socket) do
    broadcast! socket, "user:entered", %{user: msg["user"]}
    push socket, "join", %{status: "connected"}
    {:noreply, socket}
  end
  def handle_info(:ping, socket) do
    push socket, "new:msg", %{user: "SYSTEM", body: "ping"}
    {:noreply, socket}
  end

  def terminate(reason, _socket) do
    Logger.debug"> leave #{inspect reason}"
    :ok
  end

  def handle_in("new:msg", msg, socket) do
    broadcast! socket, "new:msg", %{user: msg["user"], body: msg["body"]}
    {:reply, {:ok, %{msg: msg["body"]}}, assign(socket, :user, msg["user"])}
  end
end
```

**Объявляем канал в User socket**
```elixir
#--> lib/chat_lv_web/channels/user_socket.ex
channel "rooms:*", ChatLvWeb.RoomChannel
```