import "../css/app.scss"
import { Socket, LongPoller } from "phoenix"

class App {
    static init() {
        let socket = new Socket("/socket", {
            logger: ((kind, msg, data) => { console.log(`${kind}: ${msg}`, data) })
        })

        socket.connect({ user_id: "123" })
        const status = $("#status")
        const messages = $("#messages")
        const input = $("#message-input")
        const username = $("#username")

        socket.onOpen(e => console.log("OPEN", e))
        socket.onError(e => console.log("ERROR", e))
        socket.onClose(e => console.log("CLOSE", e))

        const channel = socket.channel("rooms:lobby", {})

        channel
            .join()
            .receive("ignore", () => console.log("auth error"))
            .receive("ok", () => console.log("join ok"))

        channel.onError(e => console.log("something went wrong", e))
        channel.onClose(e => console.log("channel closed", e))

        input.off("keypress").on("keypress", e => {
            if (e.keyCode == 13) {
                channel.push("new:msg", { user: username.val(), body: input.val() })
                input.val("")
            }
        })
        
        channel.on("new:msg", msg => {
            messages.append(this.messageTemplate(msg))
            document.getElementById('messages').scrollIntoView({ behavior: 'smooth', block: 'end' })
        })

        channel.on("user:entered", msg => {
            const username = this.sanitize(msg.user || "anonymous")
            messages.append(`<br/><i>[${username} entered]</i>`)
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