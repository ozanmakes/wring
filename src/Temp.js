// module Temp

var temp = require("temp").track()
var fs = require("fs")

exports.writeSync = function (fd) {
  return function (contents) {
    return function () {
      fs.writeSync(fd, contents)
      return {}
    }
  }
}

exports.openTempSync = function (extension) {
  return function () {
    return temp.openSync({ prefix: "wring", suffix: "." + extension })
  }
}

exports.tempPath = function (extension) {
  return function () {
    return temp.path({ prefix: "wring", suffix: "." + extension });
  }
}
