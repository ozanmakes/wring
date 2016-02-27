// module PhantomjsMain

exports.setCallback = function(page) {
  return function () {
    page.onCallback = function (data) {
      console.log(data)
    }

    page.evaluate(function () {
      window.wring = window.callPhantom
    })

    return {}
  }
}

exports.setBgColor = function () {
  var bgColor = window
        .getComputedStyle(document.body)
        .getPropertyValue("background-color")

  if (!bgColor || bgColor === "rgba(0, 0, 0, 0)") {
    document.body.style.backgroundColor = "white"
  }

  return {}
}

exports.error = function (message) {
  return function () {
    require("system").stderr.write("wring: " + message + "\n")
    return {}
  }
}
