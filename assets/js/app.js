// If you want to use Phoenix channels, run `mix help phx.gen.channel`
// to get started and then uncomment the line below.
// import "./user_socket.js"

// You can include dependencies in two ways.
//
// The simplest option is to put them in assets/vendor and
// import them using relative paths:
//
//     import "../vendor/some-package.js"
//
// Alternatively, you can `npm install some-package --prefix assets` and import
// them using a path starting with the package name:
//
//     import "some-package"
//
// If you have dependencies that try to import CSS, esbuild will generate a separate `app.css` file.
// To load it, simply add a second `<link>` to your `root.html.heex` file.

// Include phoenix_html to handle method=PUT/DELETE in forms and buttons.
import "phoenix_html";
// Establish Phoenix Socket and LiveView configuration.
import { Socket } from "phoenix";
import { LiveSocket } from "phoenix_live_view";
import { hooks as colocatedHooks } from "phoenix-colocated/mdstore";
import topbar from "../vendor/topbar";
import { loadStripe } from "@stripe/stripe-js";

let Hooks = { ...colocatedHooks };
Hooks.StripeElements = {
  async mounted() {
    const stripeKey = this.el.dataset.stripeKey;
    this.stripe = await loadStripe(stripeKey);
    const elements = this.stripe.elements();

    const isDark =
      document.documentElement.getAttribute("data-theme") === "black";

    this.cardElement = elements.create("card", {
      style: {
        base: {
          fontSize: "16px",
          fontFamily: "ui-sans-serif, system-ui, sans-serif",
          color: isDark ? "#e5e7eb" : "#1f2937",
          backgroundColor: "transparent",
          iconColor: isDark ? "#d1d5db" : "#6b7280",
          "::placeholder": {
            color: isDark ? "#9ca3af" : "#9ca3af",
          },
        },
        invalid: {
          color: isDark ? "#fca5a5" : "#ef4444",
          iconColor: isDark ? "#fca5a5" : "#ef4444",
        },
      },
    });

    this.cardElement.mount(this.el);
    this.cardValid = false;

    this.cardElement.on("change", (event) => {
      const errorDiv = document.getElementById("card-error-display");
      const errorSpan = document.getElementById("card-error-text");
      const payButton = document.getElementById("pay-button");

      this.cardValid = event.complete && !event.error;

      if (event.error) {
        errorSpan.textContent = event.error.message;
        errorDiv.classList.remove("hidden");
        payButton.disabled = true;
      } else {
        errorSpan.textContent = "";
        errorDiv.classList.add("hidden");
        payButton.disabled = !event.complete;
      }
    });

    this.handleEvent("confirm_payment", async ({ client_secret }) => {
      const errorDiv = document.getElementById("card-error-display");
      const errorSpan = errorDiv.querySelector("span");

      if (!this.cardValid) {
        errorSpan.textContent = "Please enter valid card information.";
        errorDiv.classList.remove("hidden");
        this.pushEvent("payment_error", { error: "Invalid card" });
        return;
      }

      const { error, paymentIntent } = await this.stripe.confirmCardPayment(
        client_secret,
        {
          payment_method: {
            card: this.cardElement,
          },
        },
      );

      if (error) {
        errorSpan.textContent = error.message;
        errorDiv.classList.remove("hidden");
        this.pushEvent("payment_error", { error: error.message });
      } else {
        this.pushEvent("payment_success", { payment_intent: paymentIntent });
      }
    });
  },
};

const csrfToken = document
  .querySelector("meta[name='csrf-token']")
  .getAttribute("content");
const liveSocket = new LiveSocket("/live", Socket, {
  longPollFallbackMs: 2500,
  params: { _csrf_token: csrfToken },
  hooks: Hooks,
});

// Show progress bar on live navigation and form submits
topbar.config({ barColors: { 0: "#29d" }, shadowColor: "rgba(0, 0, 0, .3)" });
window.addEventListener("phx:page-loading-start", (_info) => topbar.show(300));
window.addEventListener("phx:page-loading-stop", (_info) => topbar.hide());

// connect if there are any LiveViews on the page
liveSocket.connect();

// expose liveSocket on window for web console debug logs and latency simulation:
// >> liveSocket.enableDebug()
// >> liveSocket.enableLatencySim(1000)  // enabled for duration of browser session
// >> liveSocket.disableLatencySim()
window.liveSocket = liveSocket;

// The lines below enable quality of life phoenix_live_reload
// development features:
//
//     1. stream server logs to the browser console
//     2. click on elements to jump to their definitions in your code editor
//
if (process.env.NODE_ENV === "development") {
  window.addEventListener(
    "phx:live_reload:attached",
    ({ detail: reloader }) => {
      // Enable server log streaming to client.
      // Disable with reloader.disableServerLogs()
      reloader.enableServerLogs();

      // Open configured PLUG_EDITOR at file:line of the clicked element's HEEx component
      //
      //   * click with "c" key pressed to open at caller location
      //   * click with "d" key pressed to open at function component definition location
      let keyDown;
      window.addEventListener("keydown", (e) => (keyDown = e.key));
      window.addEventListener("keyup", (e) => (keyDown = null));
      window.addEventListener(
        "click",
        (e) => {
          if (keyDown === "c") {
            e.preventDefault();
            e.stopImmediatePropagation();
            reloader.openEditorAtCaller(e.target);
          } else if (keyDown === "d") {
            e.preventDefault();
            e.stopImmediatePropagation();
            reloader.openEditorAtDef(e.target);
          }
        },
        true,
      );

      window.liveReloader = reloader;
    },
  );
}

window.addEventListener("go-back", () => {
  history.back();
});
