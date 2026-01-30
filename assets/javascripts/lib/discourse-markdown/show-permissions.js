const SHOW_PERMISSIONS_MATCHER = /\[show-permissions[^\]]*\]/;

function addShowPermissions(buffer, state, attributes, applyDataAttributes) {
  let token = new state.Token("span_open", "span", 1);
  token.attrs = [["class", "discourse-visible-permissions"]];
  applyDataAttributes(token, attributes, "category");
  buffer.push(token);

  token = new state.Token("text", "", 0);
  token.content = "";
  buffer.push(token);

  token = new state.Token("span_close", "span", -1);
  buffer.push(token);
}

function showPermissions(
  buffer,
  matches,
  state,
  { parseBBCodeTag, applyDataAttributes }
) {
  const parsed = parseBBCodeTag(matches[0], 0, matches[0].length);

  if (parsed?.tag === "show-permissions") {
    addShowPermissions(buffer, state, parsed.attrs || {}, applyDataAttributes);
  } else {
    let token = new state.Token("text", "", 0);
    token.content = matches[0];
    buffer.push(token);
  }
}

export function setup(helper) {
  helper.allowList([
    "span.discourse-visible-permissions",
    "span[data-category]",
  ]);

  helper.registerPlugin((md) => {
    md.core.textPostProcess.ruler.push("show-permissions", {
      matcher: SHOW_PERMISSIONS_MATCHER,
      onMatch: showPermissions,
    });
  });
}
