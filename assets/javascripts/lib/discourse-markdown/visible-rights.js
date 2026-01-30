const VISIBLE_RIGHTS_MATCHER = /\[visible-rights[^\]]*\]/;

function addVisibleRights(buffer, state, attributes, applyDataAttributes) {
  let token = new state.Token("span_open", "span", 1);
  token.attrs = [["class", "discourse-visible-rights"]];
  applyDataAttributes(token, attributes, "category");
  buffer.push(token);

  token = new state.Token("text", "", 0);
  token.content = "";
  buffer.push(token);

  token = new state.Token("span_close", "span", -1);
  buffer.push(token);
}

function visibleRights(
  buffer,
  matches,
  state,
  { parseBBCodeTag, applyDataAttributes }
) {
  const parsed = parseBBCodeTag(matches[0], 0, matches[0].length);

  if (parsed?.tag === "visible-rights") {
    addVisibleRights(buffer, state, parsed.attrs || {}, applyDataAttributes);
  } else {
    let token = new state.Token("text", "", 0);
    token.content = matches[0];
    buffer.push(token);
  }
}

export function setup(helper) {
  helper.allowList(["span.discourse-visible-rights", "span[data-category]"]);

  helper.registerPlugin((md) => {
    md.core.textPostProcess.ruler.push("visible-rights", {
      matcher: VISIBLE_RIGHTS_MATCHER,
      onMatch: visibleRights,
    });
  });
}
