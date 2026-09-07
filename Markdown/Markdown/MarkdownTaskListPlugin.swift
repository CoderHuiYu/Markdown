//
//  MarkdownTaskListPlugin.swift
//  Markdown
//

import Foundation

enum MarkdownTaskListPlugin {

    static let javascript = #"""
    module.exports = function taskListPlugin(md) {
        var storagePrefix = "markdown-reader-task:";

        function hash(value) {
            var result = 2166136261;
            for (var index = 0; index < value.length; index += 1) {
                result ^= value.charCodeAt(index);
                result = Math.imul(result, 16777619);
            }
            return (result >>> 0).toString(36);
        }

        function storedState(key, fallback) {
            try {
                var value = localStorage.getItem(storagePrefix + key);
                return value === null ? fallback : value === "1";
            } catch (_) {
                return fallback;
            }
        }

        md.core.ruler.after("inline", "persistent-task-lists", function (state) {
            var tokens = state.tokens;
            var occurrences = Object.create(null);
            var documentKey = hash(state.src);

            for (var index = 2; index < tokens.length; index += 1) {
                var inline = tokens[index];
                var paragraph = tokens[index - 1];
                var listItem = tokens[index - 2];

                if (inline.type !== "inline" ||
                    paragraph.type !== "paragraph_open" ||
                    listItem.type !== "list_item_open" ||
                    !inline.children || inline.children.length === 0) {
                    continue;
                }

                var firstChild = inline.children[0];
                if (firstChild.type !== "text") {
                    continue;
                }

                var marker = firstChild.content.match(/^\[([ xX])\]\s+/);
                if (!marker) {
                    continue;
                }

                var label = inline.content.replace(/^\[[ xX]\]\s+/, "").trim();
                var occurrence = occurrences[label] || 0;
                occurrences[label] = occurrence + 1;

                var taskKey = documentKey + ":" + hash(label) + ":" + occurrence;
                var checked = storedState(taskKey, marker[1].toLowerCase() === "x");
                var Token = firstChild.constructor;
                var checkbox = new Token("html_inline", "", 0);

                checkbox.content =
                    '<label class="task-list-control">' +
                    '<input class="task-list-item-checkbox" type="checkbox" ' +
                    'data-task-key="' + taskKey + '" aria-label="切换待办完成状态" ' +
                    (checked ? 'checked>' : '>') +
                    '<span class="task-list-box" aria-hidden="true"></span>' +
                    '</label>';

                firstChild.content = firstChild.content.slice(marker[0].length);
                inline.children.unshift(checkbox);
                listItem.attrJoin("class", "task-list-item");
            }
        });

        document.addEventListener("change", function (event) {
            var checkbox = event.target;
            if (!checkbox || !checkbox.classList ||
                !checkbox.classList.contains("task-list-item-checkbox")) {
                return;
            }

            try {
                localStorage.setItem(
                    storagePrefix + checkbox.dataset.taskKey,
                    checkbox.checked ? "1" : "0"
                );
            } catch (_) {
                // The checkbox remains usable when persistent storage is unavailable.
            }
        });
    };
    """#
}
