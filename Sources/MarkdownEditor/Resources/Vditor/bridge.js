(function () {
    "use strict";

    var state = {
        editor: null,
        ready: false,
        editable: false,
        allowReadOnlyTasks: true,
        suppressChange: true,
        savedRange: null,
        changeTimer: null,
        selectionTimer: null,
        resizeObserver: null,
        mutationObserver: null
    };

    function post(type, payload) {
        var handler = window.webkit &&
            window.webkit.messageHandlers &&
            window.webkit.messageHandlers.markdownEditor;
        if (!handler) {
            return;
        }
        handler.postMessage(Object.assign({type: type}, payload || {}));
    }

    function reportError(context, error) {
        var detail = error && error.message ? error.message : String(error || "未知错误");
        post("error", {message: context + "：" + detail});
    }

    function editorElement() {
        return state.editor && state.editor.vditor && state.editor.vditor.wysiwyg
            ? state.editor.vditor.wysiwyg.element
            : null;
    }

    function selectionBelongsToEditor(selection) {
        var element = editorElement();
        if (!element || !selection || selection.rangeCount === 0) {
            return false;
        }
        var container = selection.getRangeAt(0).commonAncestorContainer;
        return container === element || element.contains(container);
    }

    function saveSelection() {
        var selection = window.getSelection();
        if (!selectionBelongsToEditor(selection)) {
            return;
        }
        state.savedRange = selection.getRangeAt(0).cloneRange();
    }

    function saveSelectionAtPoint(x, y) {
        var range = document.caretRangeFromPoint
            ? document.caretRangeFromPoint(x, y)
            : null;
        if (!range && document.caretPositionFromPoint) {
            var position = document.caretPositionFromPoint(x, y);
            if (position) {
                range = document.createRange();
                range.setStart(position.offsetNode, position.offset);
                range.collapse(true);
            }
        }
        var element = editorElement();
        if (range && element && element.contains(range.startContainer)) {
            state.savedRange = range.cloneRange();
        }
    }

    function restoreSelection() {
        if (!state.savedRange) {
            return;
        }
        try {
            var selection = window.getSelection();
            selection.removeAllRanges();
            selection.addRange(state.savedRange);
        } catch (_) {
            state.savedRange = null;
        }
    }

    function anchorElement() {
        var selection = window.getSelection();
        if (!selectionBelongsToEditor(selection)) {
            return null;
        }

        var node = selection.anchorNode;
        if (node && node.nodeType === Node.ELEMENT_NODE && node.childNodes[selection.anchorOffset]) {
            node = node.childNodes[selection.anchorOffset];
        }
        return node && node.nodeType === Node.ELEMENT_NODE ? node : node && node.parentElement;
    }

    function currentBlockStyle() {
        var anchor = anchorElement();
        if (!anchor) {
            return "paragraph";
        }

        var task = anchor.closest("li.vditor-task");
        if (task) {
            return "taskList";
        }
        if (anchor.closest("li")) {
            return "unorderedList";
        }

        var block = anchor.closest("h1, h2, h3, h4, h5, h6, p, blockquote, pre");
        if (!block) {
            return "paragraph";
        }
        if (block.tagName === "H1") { return "h1"; }
        if (block.tagName === "H2") { return "h2"; }
        if (block.tagName === "H3") { return "h3"; }
        if (block.tagName === "H4") { return "h4"; }
        return "paragraph";
    }

    function scheduleSelectionReport() {
        window.clearTimeout(state.selectionTimer);
        state.selectionTimer = window.setTimeout(function () {
            saveSelection();
            post("selection", {style: currentBlockStyle()});
        }, 24);
    }

    function reportHeight() {
        window.requestAnimationFrame(function () {
            var element = editorElement();
            if (!element) {
                return;
            }
            var value = Math.max(
                element.scrollHeight,
                document.documentElement.scrollHeight,
                document.body.scrollHeight
            );
            post("height", {value: value});
        });
    }

    function canonicalizeMarkdown(markdown) {
        return String(markdown || "").replace(/^(\s*[-+*]\s+\[)X(\])/gm, "$1x$2");
    }

    function scheduleChange(markdown) {
        if (state.suppressChange) {
            return;
        }
        window.clearTimeout(state.changeTimer);
        state.changeTimer = window.setTimeout(function () {
            post("change", {markdown: canonicalizeMarkdown(markdown)});
            syncDocumentDecorations();
            reportHeight();
            scheduleSelectionReport();
        }, 80);
    }

    function toolbarButton(name) {
        var toolbar = state.editor && state.editor.vditor && state.editor.vditor.toolbar;
        var container = toolbar && toolbar.elements ? toolbar.elements[name] : null;
        return container ? container.querySelector("button") : null;
    }

    function dispatchToolbarEvent(button) {
        if (!button) {
            return false;
        }
        var eventName = navigator.userAgent.indexOf("iPhone") > -1 ? "touchstart" : "click";
        button.dispatchEvent(new Event(eventName, {bubbles: true, cancelable: true}));
        return true;
    }

    function toggleList(name) {
        var button = toolbarButton(name);
        return dispatchToolbarEvent(button);
    }

    function applyHeading(tag) {
        var toolbar = state.editor && state.editor.vditor && state.editor.vditor.toolbar;
        var container = toolbar && toolbar.elements ? toolbar.elements.headings : null;
        var button = container && container.querySelector('[data-tag="' + tag + '"]');
        return dispatchToolbarEvent(button);
    }

    function applyParagraph() {
        var current = currentBlockStyle();
        if (current === "taskList") {
            var taskButton = toolbarButton("check");
            if (taskButton) { taskButton.classList.add("vditor-menu--current"); }
            return dispatchToolbarEvent(taskButton);
        }
        if (current === "unorderedList") {
            var listButton = toolbarButton("list");
            if (listButton) { listButton.classList.add("vditor-menu--current"); }
            return dispatchToolbarEvent(listButton);
        }
        if (/^h[1-4]$/.test(current)) {
            var headingButton = toolbarButton("headings");
            if (headingButton) { headingButton.classList.add("vditor-menu--current"); }
            return dispatchToolbarEvent(headingButton);
        }
        return true;
    }

    function applyBlockStyle(style) {
        if (!state.ready || !state.editable) {
            return false;
        }

        restoreSelection();
        var applied = false;
        if (style === "paragraph") {
            applied = applyParagraph();
        } else if (style === "unorderedList") {
            applied = toggleList("list");
        } else if (style === "taskList") {
            applied = toggleList("check");
        } else if (/^h[1-4]$/.test(style)) {
            applied = applyHeading(style);
        }

        if (applied) {
            window.setTimeout(function () {
                saveSelection();
                scheduleSelectionReport();
                syncDocumentDecorations();
                reportHeight();
            }, 30);
        }
        return applied;
    }

    function syncDocumentDecorations() {
        var element = editorElement();
        if (!element) {
            return;
        }

        element.querySelectorAll("ul.md-task-list").forEach(function (list) {
            list.classList.remove("md-task-list");
        });

        element.querySelectorAll('code[data-type="html-inline"]').forEach(function (item) {
            var source = item.textContent.replace(/\u200b/g, "").trim();
            item.classList.toggle("md-inline-break", /^<br\s*\/?\s*>$/i.test(source));
        });

        element.querySelectorAll("li.vditor-task").forEach(function (item) {
            var checkbox = item.querySelector(':scope > input[type="checkbox"]');
            item.classList.toggle("md-task-checked", Boolean(checkbox && checkbox.checked));
            if (item.parentElement && item.parentElement.tagName === "UL") {
                item.parentElement.classList.add("md-task-list");
            }
        });
    }

    function setMarkdown(markdown) {
        if (!state.ready) {
            return false;
        }
        state.suppressChange = true;
        state.editor.setValue(markdown || "", true);
        window.setTimeout(function () {
            state.suppressChange = false;
            syncDocumentDecorations();
            reportHeight();
            scheduleSelectionReport();
        }, 0);
        return true;
    }

    function setEditable(editable, allowTasks) {
        state.editable = Boolean(editable);
        state.allowReadOnlyTasks = Boolean(allowTasks);
        document.documentElement.classList.toggle("md-read-only", !state.editable);
        document.documentElement.classList.toggle(
            "md-tasks-locked",
            !state.editable && !state.allowReadOnlyTasks
        );

        if (!state.ready) {
            return false;
        }
        if (state.editable) {
            state.editor.enable();
        } else {
            state.editor.disabled();
        }
        var element = editorElement();
        if (element) {
            element.setAttribute("aria-readonly", state.editable ? "false" : "true");
        }
        return true;
    }

    function setPlaceholder(placeholder) {
        var element = editorElement();
        if (!element) {
            return false;
        }
        state.editor.vditor.options.placeholder = placeholder || "";
        element.setAttribute("placeholder", placeholder || "");
        return true;
    }

    function setTheme(theme) {
        var root = document.documentElement;
        var values = theme || {};
        var mappings = {
            bodySize: "--md-body-size",
            listSize: "--md-list-size",
            heading1Size: "--md-h1-size",
            heading2Size: "--md-h2-size",
            heading3Size: "--md-h3-size",
            heading4Size: "--md-h4-size",
            inlineCodeSize: "--md-inline-code-size",
            codeSize: "--md-code-size",
            tableHeaderSize: "--md-table-header-size"
        };
        Object.keys(mappings).forEach(function (key) {
            var value = Number(values[key]);
            if (Number.isFinite(value)) {
                root.style.setProperty(mappings[key], value + "px");
            }
        });
        var lineHeight = Number(values.lineHeight);
        if (Number.isFinite(lineHeight)) {
            root.style.setProperty("--md-line-height", String(lineHeight));
        }
        if (typeof values.backgroundColor === "string" && values.backgroundColor) {
            root.style.setProperty("--md-bg", values.backgroundColor);
        }
        var insetMappings = {
            contentTopInset: "--md-content-top-inset",
            contentLeadingInset: "--md-content-leading-inset",
            contentBottomInset: "--md-content-bottom-inset",
            contentTrailingInset: "--md-content-trailing-inset"
        };
        Object.keys(insetMappings).forEach(function (key) {
            var value = Math.max(0, Number(values[key]) || 0);
            root.style.setProperty(insetMappings[key], value + "px");
        });
        root.classList.toggle("md-dark", Boolean(values.isDark));
        reportHeight();
        return true;
    }

    function setFormattingBarInset(inset) {
        var value = Math.max(0, Number(inset) || 0);
        document.documentElement.style.setProperty("--md-formatting-inset", value + "px");
        return true;
    }

    function bindDocumentEvents() {
        document.addEventListener("selectionchange", scheduleSelectionReport);

        document.addEventListener("click", function (event) {
            var target = event.target && event.target.closest ? event.target : null;
            var anchor = target && target.closest("a");
            if (anchor && !state.editable) {
                event.preventDefault();
                event.stopPropagation();
                post("link", {url: anchor.href});
                return;
            }
            if (target && target.matches('input[type="checkbox"]')) {
                window.setTimeout(function () {
                    syncDocumentDecorations();
                    reportHeight();
                }, 0);
                return;
            }
            if (!state.editable) {
                saveSelectionAtPoint(event.clientX, event.clientY);
                post("requestEdit");
            }
        }, true);

        var element = editorElement();
        if (!element) {
            return;
        }

        state.resizeObserver = new ResizeObserver(reportHeight);
        state.resizeObserver.observe(element);

        state.mutationObserver = new MutationObserver(function () {
            syncDocumentDecorations();
            reportHeight();
        });
        state.mutationObserver.observe(element, {
            subtree: true,
            childList: true,
            attributes: true,
            attributeFilter: ["checked"]
        });

        if (window.visualViewport) {
            window.visualViewport.addEventListener("resize", reportHeight);
        }
    }

    function initialize() {
        try {
            state.editor = new Vditor("editor", {
                cdn: ".",
                lang: "zh_CN",
                i18n: window.VditorI18n,
                // Vditor normally loads this with a synchronous XHR. WKWebView
                // intentionally preloads the SVG symbols from editor.html instead.
                icon: "",
                mode: "wysiwyg",
                height: "100%",
                minHeight: 0,
                width: "100%",
                value: "",
                placeholder: "",
                cache: {enable: false},
                counter: {enable: false},
                outline: {enable: false},
                resize: {enable: false},
                toolbar: ["headings", "list", "check"],
                toolbarConfig: {hide: true, pin: false},
                hint: {parse: false, emoji: {}, extend: []},
                link: {isOpen: false},
                image: {isPreview: false},
                preview: {
                    delay: 80,
                    maxWidth: 760,
                    mode: "editor",
                    hljs: {enable: false, lineNumber: false, style: "github"},
                    theme: {
                        current: "earbuds",
                        list: {earbuds: "Earbuds"},
                        path: "./dist/css/content-theme"
                    },
                    render: {media: {enable: false}}
                },
                input: function (value) {
                    scheduleChange(value);
                },
                focus: function () {
                    post("focus");
                    scheduleSelectionReport();
                },
                blur: function () {
                    post("blur");
                    scheduleSelectionReport();
                },
                select: function () {
                    saveSelection();
                    scheduleSelectionReport();
                },
                after: function () {
                    state.ready = true;
                    state.suppressChange = false;
                    bindDocumentEvents();
            syncDocumentDecorations();
                    reportHeight();
                    post("ready");
                }
            });
        } catch (error) {
            reportError("初始化失败", error);
        }
    }

    window.addEventListener("error", function (event) {
        reportError("页面错误", event.error || event.message);
    });
    window.addEventListener("unhandledrejection", function (event) {
        reportError("脚本异常", event.reason);
    });

    window.MarkdownBridge = {
        setMarkdown: setMarkdown,
        getMarkdown: function () {
            return state.ready ? canonicalizeMarkdown(state.editor.getValue()) : "";
        },
        setEditable: setEditable,
        setPlaceholder: setPlaceholder,
        setTheme: setTheme,
        setFormattingBarInset: setFormattingBarInset,
        applyBlockStyle: applyBlockStyle,
        focus: function () {
            if (state.ready && state.editable) {
                state.editor.focus();
                restoreSelection();
                scheduleSelectionReport();
            }
        },
        blur: function () {
            if (state.ready) { state.editor.blur(); }
        }
    };

    initialize();
}());
