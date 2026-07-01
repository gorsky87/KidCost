const scenarios = [
  {
    who: "Rodzic po zakupach",
    what: "Dodać koszt, przypiąć paragon i od razu zobaczyć wpływ na saldo.",
    when: "Kiedy wraca z zakupów i chce zamknąć temat zanim zniknie paragon.",
  },
  {
    who: "Rodzic po wizycie lekarskiej",
    what: "Zapisać rachunek medyczny, EOB, dostawcę i kwotę out-of-pocket.",
    when: "Kiedy koszt wymaga faktów, ale nie powinien zmieniać tonu rozmowy.",
  },
  {
    who: "Rodzic planujący wyjazd",
    what: "Uzgodnić planowany zakup albo koszt wakacyjny przed płatnością.",
    when: "Kiedy decyzja powinna być wspólna, zanim pojawi się realny wydatek.",
  },
  {
    who: "Rodzic ogarniający szkołę",
    what: "Utworzyć szablon cyklicznego kosztu i później potwierdzić go jako wydatek.",
    when: "Kiedy czesne, zajęcia albo korepetycje wracają co miesiąc.",
  },
];

const formatter = new Intl.NumberFormat("pl-PL", {
  style: "currency",
  currency: "PLN",
});

document.body.classList.add("reveal-ready");

function setScenario(index) {
  const scenario = scenarios[index];
  document.querySelector("#scenario-who").textContent = scenario.who;
  document.querySelector("#scenario-what").textContent = scenario.what;
  document.querySelector("#scenario-when").textContent = scenario.when;

  document.querySelectorAll(".scenario-tab").forEach((button, buttonIndex) => {
    button.classList.toggle("active", buttonIndex === index);
    button.setAttribute("aria-selected", buttonIndex === index ? "true" : "false");
  });
  revealVisibleNow();
}

function parseAmount(input) {
  const value = Number.parseFloat(input.value.replace(",", "."));
  return Number.isFinite(value) && value > 0 ? value : 0;
}

function updateDemo() {
  const you = parseAmount(document.querySelector("#paid-you"));
  const other = parseAmount(document.querySelector("#paid-other"));
  const difference = (you - other) / 2;
  const result = document.querySelector("#demo-result");

  if (Math.abs(difference) < 0.005) {
    result.textContent = "Saldo jest wyrównane";
    return;
  }

  if (difference > 0) {
    result.textContent = `Drugi rodzic oddaje Tobie ${formatter.format(difference)}`;
    return;
  }

  result.textContent = `Ty oddajesz drugiemu rodzicowi ${formatter.format(
    Math.abs(difference),
  )}`;
}

function revealVisibleEntries(entries) {
  entries.forEach((entry) => {
    if (entry.isIntersecting) {
      entry.target.classList.add("visible");
    }
  });
}

function revealElementIfVisible(element) {
  const rect = element.getBoundingClientRect();
  if (rect.top < window.innerHeight * 0.92 && rect.bottom > 0) {
    element.classList.add("visible");
  }
}

function revealVisibleNow() {
  document.querySelectorAll("[data-reveal]").forEach(revealElementIfVisible);
}

document.querySelectorAll(".scenario-tab").forEach((button) => {
  button.addEventListener("click", () => {
    setScenario(Number(button.dataset.scenario));
  });
});

document.querySelectorAll(".demo-card input").forEach((input) => {
  input.addEventListener("input", updateDemo);
});

const observer = new IntersectionObserver(revealVisibleEntries, {
  threshold: 0.15,
});

document.querySelectorAll("[data-reveal]").forEach((element) => {
  observer.observe(element);
});

window.addEventListener("scroll", revealVisibleNow, { passive: true });
window.addEventListener("resize", revealVisibleNow);

setScenario(0);
updateDemo();
requestAnimationFrame(revealVisibleNow);
