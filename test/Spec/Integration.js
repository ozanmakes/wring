// module Test.Spec.IntegrationSpec

var spawn = require("child_process").spawn
var http = require("http")
var fs = require("fs")

exports.runImpl = function (args) {
  return function (cb) {
    return function () {
      var result = ""
      var command = spawn("node", ["wring.js"].concat(args), {
        silent: true
      })

      command.stdout.on("data", function(data) {
        result += data.toString()
      })

      command.on("close", function(code) {
        return cb({ output: result.slice(0, -1), code: code })()
      })

      return {}
    }
  }
}

exports.shImpl = function (cmd) {
  return function (cb) {
    return function () {
      var result = ""
      var command = spawn("sh", ["-c", cmd], {
        silent: true
      })

      command.stdout.on("data", function(data) {
        result += data.toString()
      })

      command.on("close", function(code) {
        return cb(result.slice(0, -1))()
      })

      return {}
    }
  }
}

exports.startServer = function (data) {
  return function (cb) {
    return function () {
      var server = http.createServer(function (req, res) {
        res.end(data + "\n")
        this.close()
      })

      server.listen(0, "127.0.0.1", function (err) {
        if (err) throw err

        cb("http://" + server.address().address + ":" + server.address().port)()
      })

      return {}
    }
  }
}

exports.isPng = function (filepath) {
  return function () {
    var buf = new Buffer(8)
    var fd = fs.openSync(filepath, "r")
    var bytesRead = fs.readSync(fd, buf, 0, 8, 0)

    fs.closeSync(fd)

    if (bytesRead < 8) {
      buf = buf.slice(0, bytesRead)
    }

    return (buf[0] === 0x89 &&
            buf[1] === 0x50 &&
            buf[2] === 0x4E &&
            buf[3] === 0x47)
  }
}
