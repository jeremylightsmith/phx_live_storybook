export const SearchHook = {
  mounted() {
    const searchContainer = document.querySelector("#search-container");
    const searchModal = document.querySelector("#search-modal");
    const searchList = document.querySelector("#search-list");
    const searchInput = document.querySelector("#search-input");

    let allEntries = searchList.children;
    let firstEntry = searchList.firstElementChild;
    let lastEntry = searchList.lastElementChild;
    let activeEntry = firstEntry;

    let observer = new MutationObserver((mutations) => {
      allEntries = searchList.children;
      firstEntry = searchList.firstElementChild;
      lastEntry = searchList.lastElementChild;

      if (allEntries.length > 0) {
        this.liveSocket.execJS(
          activeEntry,
          activeEntry.getAttribute("phx-baseline")
        );
        activeEntry = firstEntry;
        this.liveSocket.execJS(
          activeEntry,
          activeEntry.getAttribute("phx-highlight")
        );
      }
    });

    observer.observe(searchList, {
      childList: true,
    });

    window.addEventListener("lsb:open-search", () => {
      this.liveSocket.execJS(
        searchContainer,
        searchContainer.getAttribute("phx-show")
      );
      this.liveSocket.execJS(searchModal, searchModal.getAttribute("phx-show"));
      setTimeout(() => searchInput.focus(), 50);
      this.liveSocket.execJS(
        activeEntry,
        activeEntry.getAttribute("phx-highlight")
      );
    });

    window.addEventListener("lsb:close-search", () => {
      this.liveSocket.execJS(searchModal, searchModal.getAttribute("phx-hide"));
      this.liveSocket.execJS(
        searchContainer,
        searchContainer.getAttribute("phx-hide")
      );
    });

    window.addEventListener("keydown", (e) => {
      if ((e.metaKey && (e.key === "k" || e.key === "K")) || e.key === "/") {
        e.preventDefault();
        this.dispatchOpenSearch();
      }
    });

    [...allEntries].forEach((entry) => {
      entry.addEventListener("mouseover", (e) => {
        if (e.movementX != 0 && e.movementY != 0 && e.target == entry) {
          // This prevents clipping when switching back and forth
          // between mouse navigation and keyboard navigation

          this.liveSocket.execJS(
            activeEntry,
            activeEntry.getAttribute("phx-baseline")
          );
          activeEntry = e.target;
          this.liveSocket.execJS(
            activeEntry,
            activeEntry.getAttribute("phx-highlight")
          );
        }
      });
    });

    searchContainer.addEventListener("keydown", (e) => {
      if (e.key === "Enter") {
        e.preventDefault();
        const link = activeEntry.firstElementChild;

        this.resetInput(searchInput);
        this.pushEventTo("#search-container", "navigate", {
          path: link.pathname,
        });
        this.dispatchCloseSearch();
      }

      if (e.key === "Escape") {
        this.dispatchCloseSearch();
      }

      if (e.key === "Tab") {
        // This prevents the use of tab within the search modal
        // to keep the focus in the search input.
        e.preventDefault();
      }

      if (e.key === "ArrowUp") {
        this.liveSocket.execJS(
          activeEntry,
          activeEntry.getAttribute("phx-baseline")
        );

        if (activeEntry == firstEntry) {
          activeEntry = lastEntry;
        } else {
          activeEntry = activeEntry.previousElementSibling;
        }

        this.liveSocket.execJS(
          activeEntry,
          activeEntry.getAttribute("phx-highlight")
        );
        activeEntry.scrollIntoView({ block: "nearest", inline: "nearest" });
      }

      if (e.key === "ArrowDown") {
        this.liveSocket.execJS(
          activeEntry,
          activeEntry.getAttribute("phx-baseline")
        );

        if (activeEntry == lastEntry) {
          activeEntry = firstEntry;
        } else {
          activeEntry = activeEntry.nextElementSibling;
        }

        this.liveSocket.execJS(
          activeEntry,
          activeEntry.getAttribute("phx-highlight")
        );
        activeEntry.scrollIntoView({ block: "nearest", inline: "nearest" });
      }
    });

    searchList.addEventListener("click", (e) => {
      const link = activeEntry.firstElementChild;

      this.resetInput(searchInput);
      this.pushEventTo("#search-container", "navigate", {
        path: link.pathname,
      });
      this.dispatchCloseSearch();
    });
  },

  resetInput(searchInput) {
    searchInput.value = "";
    this.pushEventTo("#search-container", "search", { search: { input: "" } });
  },

  dispatchOpenSearch() {
    const event = new Event("lsb:open-search");
    window.dispatchEvent(event);
  },

  dispatchCloseSearch() {
    const event = new Event("lsb:close-search");
    window.dispatchEvent(event);
  },
};
