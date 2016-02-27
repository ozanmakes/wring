// module Cheerio

var cheerio = require("cheerio")
var xpath = require("xpath")
var xmldom = require("xmldom")

exports.load = function (document) {
  return function () {
    return cheerio.load(document)
  }
}

exports.get = function (method) {
  return function (coll) {
    return function () {
      var result = ""

      cheerio(coll).each(function (idx, el) {
        var $el = cheerio(el)
        result += cheerio[method]($el).trim() + "\n"
      })

      return result.trim()
    }
  }
}

exports.selectXpath = function ($) {
  return function (selector) {
    return function () {
      var xhtml = $.xml()
      var dom = new xmldom.DOMParser({ errorHandler: {} })
      var doc = dom.parseFromString(xhtml)
      var nodes = xpath.select(selector, doc)

      return cheerio.load(nodes.join(""), { xmlMode: true }).root().children()
    }
  }
}
