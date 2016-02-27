// module Input

exports.isFileSync = function (path) {
  return function () {
    try {
      return require("fs").statSync(path).isFile()
    }
    catch (e) {
      return false
    }
  }
}
