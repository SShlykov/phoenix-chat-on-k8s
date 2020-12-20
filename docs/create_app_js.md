**Создадим класс, который прикрепляет прослушивание событий, связанных с комнатой**
```js
#--> assets/js/app.js

import "../css/app.scss"
import { Socket, LongPoller } from "phoenix"

class App {
  static init() {
    let socket = new Socket("/socket", {
      logger: ((kind, msg, data) => { console.log(`${kind}: ${msg}`, data) })
    })

    socket.connect({ user_id: "123" })
    var $status = $("#status")
    var $messages = $("#messages")
    var $input = $("#message-input")
    var $username = $("#username")

    socket.onOpen(ev => console.log("OPEN", ev))
    socket.onError(ev => console.log("ERROR", ev))
    socket.onClose(e => console.log("CLOSE", e))

    var channel = socket.channel("rooms:lobby", {})
    
    channel
    .join()
    .receive("ignore", () => console.log("auth error"))
    .receive("ok", () => console.log("join ok"))

    channel.onError(e => console.log("something went wrong", e))
    channel.onClose(e => console.log("channel closed", e))

    $input.off("keypress").on("keypress", e => {
      if (e.keyCode == 13) {
        channel.push("new:msg", { user: $username.val(), body: $input.val() })
        $input.val("")
      }
    })

    channel.on("new:msg", msg => {
      $messages.append(this.messageTemplate(msg))
      document.getElementById('messages').scrollIntoView({ behavior: 'smooth', block: 'end' })
    })

    channel.on("user:entered", msg => {
      var username = this.sanitize(msg.user || "anonymous")
      $messages.append(`<br/><i>[${username} entered]</i>`)
    })
  }

  static sanitize(html) { return $("<div/>").text(html).html() }

  static messageTemplate(msg) {
    let username = this.sanitize(msg.user || "anonymous")
    let body = this.sanitize(msg.body)

    return (`<p><a href='#'>[${username}]</a>&nbsp; ${body}</p>`)
  }

}

$(() => App.init())

export default App
```