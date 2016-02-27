// module Main

exports.phantomjsPath = function () {
  try {
    return require("phantomjs-prebuilt").path
  }
  catch (e) {
    return "phantomjs"
  }
}
