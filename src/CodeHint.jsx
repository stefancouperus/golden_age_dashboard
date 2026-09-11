import React, {
  useEffect,
  useId,
  useLayoutEffect,
  useRef,
  useState,
} from "react";
import { CODES } from "./domain.js";

// A native popover stays above the scrolling matrix and mobile speech dialog.
// The definitions come from the same codebook objects used by About.
export function CodeHint({
  codes,
  as: Tag = "span",
  focusable = true,
  preserveClick = false,
  focusOnly = false,
  children,
  ...props
}) {
  const id = useId();
  const anchor = useRef(null),
    popup = useRef(null),
    timer = useRef(null),
    pinned = useRef(false);
  const [open, setOpen] = useState(false);
  const definitions = [...new Set(codes)]
    .map((code) => CODES[code])
    .filter(Boolean);
  const cancelClose = () => clearTimeout(timer.current);
  const show = () => {
    cancelClose();
    window.dispatchEvent(
      new CustomEvent("golden-age-code-hint-open", { detail: id }),
    );
    setOpen(true);
  };
  const hide = () => {
    cancelClose();
    pinned.current = false;
    setOpen(false);
  };
  function leave(event) {
    if (pinned.current || anchor.current?.contains(event.relatedTarget)) return;
    cancelClose();
    timer.current = setTimeout(hide, 180);
  }
  useEffect(() => () => clearTimeout(timer.current), []);
  useEffect(() => {
    const dismissOther = (event) => {
      if (event.detail !== id) hide();
    };
    window.addEventListener("golden-age-code-hint-open", dismissOther);
    return () =>
      window.removeEventListener("golden-age-code-hint-open", dismissOther);
  }, [id]);
  useLayoutEffect(() => {
    const element = popup.current;
    if (!open || !element) return;
    if (element.showPopover && !element.matches(":popover-open"))
      element.showPopover();
    const target = anchor.current.getBoundingClientRect();
    const box = element.getBoundingClientRect();
    const left = Math.max(
      12,
      Math.min(target.left, innerWidth - box.width - 12),
    );
    const above = target.top - box.height - 8;
    const top = Math.max(
      12,
      Math.min(
        above >= 12 ? above : target.bottom + 8,
        innerHeight - box.height - 12,
      ),
    );
    element.style.left = `${left}px`;
    element.style.top = `${top}px`;
    const outside = (event) => {
      if (!anchor.current?.contains(event.target)) hide();
    };
    const escape = (event) => {
      if (event.key === "Escape") {
        event.preventDefault();
        event.stopPropagation();
        hide();
      }
    };
    const scroll = (event) => {
      if (!popup.current?.contains(event.target)) hide();
    };
    document.addEventListener("pointerdown", outside, true);
    document.addEventListener("keydown", escape, true);
    window.addEventListener("scroll", scroll, true);
    window.addEventListener("resize", hide);
    return () => {
      document.removeEventListener("pointerdown", outside, true);
      document.removeEventListener("keydown", escape, true);
      window.removeEventListener("scroll", scroll, true);
      window.removeEventListener("resize", hide);
      if (element.hidePopover && element.matches(":popover-open"))
        element.hidePopover();
    };
  }, [open]);
  const click = (event) => {
    if (preserveClick) {
      if (Tag === "button") hide();
      props.onClick?.(event);
      return;
    }
    event.preventDefault();
    event.stopPropagation();
    if (pinned.current) hide();
    else {
      pinned.current = true;
      show();
    }
  };
  return (
    <Tag
      {...props}
      ref={anchor}
      tabIndex={Tag === "span" && focusable ? 0 : undefined}
      role={Tag === "span" && focusable ? "button" : undefined}
      aria-describedby={[props["aria-describedby"], id]
        .filter(Boolean)
        .join(" ")}
      aria-expanded={!preserveClick && focusable ? open : undefined}
      data-code-hint={codes.join(" ")}
      onPointerEnter={(event) => {
        if (!focusOnly && event.pointerType !== "touch") show();
      }}
      onPointerLeave={leave}
      onFocus={show}
      onBlur={leave}
      onClick={click}
      onKeyDown={(event) => {
        if (Tag === "span" && focusable && ["Enter", " "].includes(event.key))
          click(event);
      }}
    >
      {Tag === "label"
        ? React.Children.map(children, (child) =>
            React.isValidElement(child) && child.type === "input"
              ? React.cloneElement(child, { "aria-describedby": id })
              : child,
          )
        : children}
      <span
        ref={popup}
        id={id}
        className="code-hint-popup"
        role="tooltip"
        popover="manual"
        hidden={!open}
        onToggle={(event) => {
          if (event.newState === "closed") {
            pinned.current = false;
            setOpen(false);
          }
        }}
        onPointerEnter={cancelClose}
        onPointerLeave={leave}
        onClick={(event) => {
          event.preventDefault();
          event.stopPropagation();
        }}
      >
        {definitions.map((code) => (
          <span className="code-hint-definition" key={code.id}>
            <strong>
              <span
                className="code-hint-swatch"
                style={{ background: code.color }}
                aria-hidden="true"
              />
              {code.id} · {code.label}
            </strong>
            <span>{code.meaning}</span>
          </span>
        ))}
      </span>
    </Tag>
  );
}
