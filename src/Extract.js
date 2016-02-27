// module Extract

exports.extractImpl = function (cmd, selector) {
  var coll, nodes, iterator, thisNode
  var output = ""

  try {
    if (selector[0] === "/") {
      nodes = []
      iterator = window.document.evaluate(
        selector,
        window.document,
        null,
        window.XPathResult.ORDERED_NODE_ITERATOR_TYPE,
        null
      )
      thisNode = iterator.iterateNext()

      while (thisNode) {
        nodes.push(thisNode)
        thisNode = iterator.iterateNext()
      }

      coll = nodes
    } else {
      coll = window.jQuery(selector).toArray()
    }

    if (cmd === "text" || cmd === "html") {
      coll.forEach(function (el) {
        output += (cmd === "text"
                   ? el.textContent.trim()
                   : el.outerHTML) + "\n"
      })

      return { output: output.trim() }
    } else if (cmd === "rect") {
      if (coll.length > 0) {
        return { rect: coll[0].getBoundingClientRect() }
      } else {
        return {
          error: "Selector '" + selector + "' didn't match any elements"
        }
      }

    }
  }
  catch (e) {
    if (e instanceof XPathException) {
      return { error: "Invalid XPath expression: " + selector }
    } else {
      return { error: e.message }
    }
  }
}
