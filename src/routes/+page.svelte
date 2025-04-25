<script lang="ts">
  import { onMount } from 'svelte';
  import { writable, derived } from 'svelte/store';
  import { getHolidaysForYear, optimizeDaysOff } from '$lib/ptoOptimizer';
  import { ptoData } from '$lib/countryData';

  const currentYear = new Date().getFullYear();
  const year = writable(currentYear);
  const selectedCountry = writable('PT');
  const ptoDays = writable(ptoData['PT']);

  const holidays = writable([]);
  const suggestedDaysOff = writable([]);
  const toggledDays = writable(new Set());
  const rejectedSuggestions = writable(new Set<string>());
  const isEditing = writable(false);
  const isClear = writable(true);
  const countryNames = new Intl.DisplayNames(['en'], { type: 'region' });
  function countryFlagEmoji(code: string): string {
    return code
      .toUpperCase()
      .replace(/./g, char => String.fromCodePoint(127397 + char.charCodeAt(0)));
  }

  $: if (selectedCountry && ptoData[$selectedCountry]) {
    ptoDays.set(ptoData[$selectedCountry]);
    updateHolidays($year, $selectedCountry);
    resetState();
  }

  async function updateHolidays(y: number, country: string) {
    const holidayList = getHolidaysForYear(country, y);
    holidays.set(holidayList.map(h => ({ date: new Date(h.date) })));
  }

  function recalculateSuggestions() {
    const optimized = optimizeDaysOff($holidays.map(h => ({ date: new Date(h.date) })), $year, $ptoDays);
    suggestedDaysOff.set(optimized);
    isClear.set(false);
  }

  function applySuggestedDays() {
    toggledDays.set(new Set($suggestedDaysOff.map(d => d.toDateString())));
    isEditing.set(true);
  }

  function cancelEdits() {
    toggledDays.set(new Set());
    isEditing.set(false);
  }

  function clearAllSelections() {
    toggledDays.set(new Set());
    suggestedDaysOff.set([]);
    rejectedSuggestions.set(new Set());
    isEditing.set(false);
    isClear.set(true);
  }

  function resetState() {
    toggledDays.set(new Set());
    suggestedDaysOff.set([]);
    rejectedSuggestions.set(new Set());
    isEditing.set(false);
    isClear.set(true);
  }
  function toggleDay(date: Date) {
    const key = date.toDateString();
    const isSuggested = $suggestedDaysOff.some(d => d.toDateString() === key);
    const isSelected = $toggledDays.has(key);
    const currentCount = $toggledDays.size;

    if (!isSelected && currentCount >= $ptoDays) return;

    const newToggled = new Set($toggledDays);
    const newRejected = new Set($rejectedSuggestions);

    if (isSelected) {
      newToggled.delete(key);
      if (isSuggested) newRejected.add(key);
    } else {
      newToggled.add(key);
      newRejected.delete(key);
    }

    toggledDays.set(newToggled);
    rejectedSuggestions.set(newRejected);
  }

  const usedPTO = derived(toggledDays, $toggledDays => $toggledDays.size);

  const totalDaysOff = derived([toggledDays, holidays, year], ([$toggled, $holidays, $year]) => {
    const offDays = new Set<string>();

    // Build a set of holidays and PTOs
    const importantDays = new Set<string>();
    for (const h of $holidays) importantDays.add(h.date.toDateString());
    for (const t of $toggled) importantDays.add(t);

    for (let d = new Date($year, 0, 1); d.getFullYear() === $year; d.setDate(d.getDate() + 1)) {
      const dateStr = d.toDateString();

      const prevDay = new Date(d);
      prevDay.setDate(d.getDate() - 1);
      const nextDay = new Date(d);
      nextDay.setDate(d.getDate() + 1);

      const isWeekend = d.getDay() === 0 || d.getDay() === 6;

      if (
        importantDays.has(dateStr) ||
        (isWeekend &&
          (importantDays.has(prevDay.toDateString()) || importantDays.has(nextDay.toDateString())))
      ) {
        offDays.add(dateStr);
      }
    }

    return offDays.size;
  });


  function getMonthMatrix(month: number, year: number): (Date | null)[][] {
    const days = [];
    const firstDay = new Date(year, month, 1).getDay();
    const totalDays = new Date(year, month + 1, 0).getDate();
    let dayCounter = 1;
    const offset = firstDay === 0 ? 6 : firstDay - 1;

    for (let i = 0; i < 6; i++) {
      const week = [];
      for (let j = 0; j < 7; j++) {
        if ((i === 0 && j < offset) || dayCounter > totalDays) {
          week.push(null);
        } else {
          week.push(new Date(year, month, dayCounter++));
        }
      }
      days.push(week);
      if (dayCounter > totalDays) break;
    }
    return days;
  }

  $: ptoError = $ptoDays < 0 ? 'Enter a number 0 or greater' : '';
  function incrementPTO() {
    ptoDays.update(n => n + 1);
    resetState();
  }
  function decrementPTO() {
    ptoDays.update(n => Math.max(0, n - 1));
    resetState();
  }
</script>

<style>
  :global(body) {
    background: linear-gradient(180deg, #0a1b2c 0%, #0f2a45 100%);
    color: #ffffff;
    font-family: sans-serif;
    margin: 0;
    padding: 2rem;
  }

  .controls,
  .pto-selector,
  .metrics,
  .action-buttons,
  .legend {
    display: flex;
    flex-wrap: wrap;
    justify-content: center;
    align-items: center;
    gap: 1rem;
    margin-top: 1rem;
  }

  .controls {
    margin-top: 2rem;
  }

  .metrics {
    flex-direction: column;
    margin-top: 1rem;
  }

  .action-buttons {
    flex-wrap: wrap;
    margin-top: 1.5rem;
  }

  .legend {
    gap: 0.75rem;
    margin-top: 1.5rem;
  }

  .calendar-container {
    display: flex;
    flex-direction: column;
    gap: 2rem;
    padding-top: 1rem;
  }

  .calendar-row {
    display: grid;
    grid-template-columns: repeat(3, 1fr);
    gap: 2rem;
  }

  .month {
    padding: 0.5rem;
  }

  .month h3 {
    text-align: center;
    margin-bottom: 0.8rem;
    font-size: 1.25rem;
    font-weight: 600;
  }

  .week-labels,
  .week {
    display: grid;
    grid-template-columns: repeat(7, 2rem);
    gap: 0.4rem;
    justify-content: center;
  }

  .label {
    width: 2rem;
    height: 2rem;
    text-align: center;
    font-weight: bold;
    font-size: 0.75rem;
    color: white;
    opacity: 1;
  }

  .day {
    background-color: #1e293b;
    border-radius: 6px;
    transition: background 0.2s ease;
    width: 2rem;
    height: 2rem;
    text-align: center;
    line-height: 2rem;
    border: 1px solid rgba(255, 255, 255, 0.1);
    cursor: pointer;
  }

  .day:hover {
    background-color: #334155;
  }

  .holiday {
    background-color: #f59e0b;
    color: #000;
  }

  .suggested {
    background-color: #2dd4bf;
    color: #000;
  }

  .toggled {
    background-color: #22c55e !important;
    color: white;
  }

  .saturday {
    background-color: #475569;
  }

  .sunday {
    background-color: #64748b;
  }

  .hero {
    text-align: center;
    margin-top: 4rem;
    margin-bottom: 2rem;
    max-width: 700px;
    margin-left: auto;
    margin-right: auto;
  }

  .hero h1 {
    font-size: 2.2rem;
    font-weight: 800;
  }

  .hero p {
    font-size: 1.05rem;
    margin: 0.5rem 0;
    line-height: 1.5;
  }

  .footer {
    text-align: center;
    margin-top: 2rem;
    font-size: 0.9rem;
    color: #bbb;
    padding: 1rem 0;
  }

  .footer p {
    margin: 0;
  }

  .button {
    background: #3b82f6;
    border-radius: 6px;
    padding: 0.5rem 1rem;
    font-weight: 600;
    transition: background 0.2s;
    border: none;
    color: white;
    cursor: pointer;
  }

  .button:hover {
    background: #2563eb;
  }

  .button:disabled {
    background: #999;
    cursor: not-allowed;
  }

  .legend span {
    padding: 2px 6px;
    margin-right: 1rem;
    border-radius: 4px;
    font-size: 0.85rem;
    font-weight: 500;
  }

  .legend.compact {
    position: absolute;
    top: 1rem;
    left: 2rem;
    display: flex;
    flex-direction: column;
    gap: 0.4rem;
    font-size: 0.75rem;
    background: rgba(0, 0, 0, 0.4);
    padding: 0.5rem 0.75rem;
    border-radius: 6px;
    box-shadow: 0 0 4px rgba(0,0,0,0.3);
  }

  .label.pto {
    background: #22c55e;
    color: white;
    padding: 2px 6px;
    border-radius: 4px;
  }

  .label.holiday {
    background: orange;
    color: black;
    padding: 2px 6px;
    border-radius: 4px;
  }

  .label.suggested {
    background: #2dd4bf;
    color: black;
    padding: 2px 6px;
    border-radius: 4px;
  }
  .legend-compact {
    display: flex;
    gap: 1rem;
    font-size: 0.75rem;
    margin: 1rem 0 0.5rem 0;
    padding-left: 0.25rem;
    align-items: center;
    justify-content: flex-start;
  }
  .legend-box {
    position: absolute;
    top: 23rem;
    left: 1rem;
    background-color: #0f172a;
    padding: 0.75rem;
    border-radius: 8px;
    box-shadow: 0 0 10px rgba(0,0,0,0.3);
    display: flex;
    flex-direction: column;
    gap: 0.5rem;
    font-size: 0.8rem;
    color: white;
    z-index: 10;
  }

  .legend-item {
    display: flex;
    align-items: center;
    gap: 0.5rem;
  }

  .swatch {
    width: 16px;
    height: 16px;
    border-radius: 4px;
    display: inline-block;
  }

  .swatch.pto {
    background-color: #22c55e;
  }

  .swatch.holiday {
    background-color: orange;
  }

  .swatch.suggested {
    background-color: #2dd4bf;
  }

  .app-header {
    max-width: 720px;
    margin: 2rem auto 1.5rem;
    text-align: center;
  }

  .app-header h1 {
    font-size: 2.5rem;
    font-weight: 800;
    margin-bottom: 0.5rem;
  }

  .app-header p {
    font-size: 1.05rem;
    line-height: 1.6;
    color: #ddd;
  }

</style>

<header class="app-header">
  <h1>🧠 Holiday Time Hacker</h1>
  <p>
    Take control of your time off. This tool helps you find the smartest way to use your vacation days by 
    aligning them with public holidays and weekends — turning a handful of days into full-blown getaways.
  </p>
</header>

<section class="hero">
  <div class="controls single-line">
    <span>In</span>

    <select bind:value={$selectedCountry}>
      {#each Object.keys(ptoData).sort() as code}
        <option value={code}>
          {countryNames.of(code)} {countryFlagEmoji(code)}
        </option>
      {/each}
    </select>

    <span>
      {countryFlagEmoji($selectedCountry)} <strong>{countryNames.of($selectedCountry)}</strong>,
      you’ve got
    </span>

    <button on:click={decrementPTO} aria-label="Decrease PTO">–</button>
    <span class="pto-count">{$ptoDays}</span>
    <button on:click={incrementPTO} aria-label="Increase PTO">+</button>

    <span>days off and <strong>{$holidays.length}</strong> public holidays in</span><span>
        <button on:click={() => {year.update(y => y - 1); resetState(); }} disabled={$year <= currentYear}>◀</button>
    <strong>{$year}</strong>
    <button on:click={() => {year.update(y => y + 1); resetState(); }} disabled={$year >= currentYear + 10}>▶</button></span>


  </div>
</section>


<div class="action-buttons"> 
  {#if !$isEditing}
    <button class="button" on:click={applySuggestedDays}>✏️ Edit </button>
  {/if}  
  {#if !$isEditing && $isClear}
    <button class="button" on:click={recalculateSuggestions}>✨ Calculate</button>
  {/if}  
  
  {#if $isEditing}
    <button class="button" on:click={cancelEdits}>❌ Cancel </button>
  {/if}
  {#if !$isClear}
    <button class="button" on:click={clearAllSelections}>🧹 Clear </button>
  {/if}
</div>


<div class="legend-box">
  <div class="legend-item">
    <span class="swatch pto"></span> <span>PTO</span>
  </div>
  <div class="legend-item">
    <span class="swatch holiday"></span> <span>Holiday</span>
  </div>
  <div class="legend-item">
    <span class="swatch suggested"></span> <span>Suggested</span>
  </div>
</div>

<div class="metrics">
  🎉 Total Days Off: {$totalDaysOff}   🗓 Used Days: {$usedPTO} / {$ptoDays}
</div>

<div class="calendar-container">
  {#each [0, 1, 2, 3] as rowIndex}
    <div class="calendar-row">
      {#each [0, 1, 2] as colIndex}
        {#if rowIndex * 3 + colIndex < 12}
          <div class="month">
            <h3>{new Date($year, rowIndex * 3 + colIndex).toLocaleString('default', { month: 'long' })}</h3>
            <div class="week-labels">
              {#each ['Mo', 'Tu', 'We', 'Th', 'Fr', 'Sa', 'Su'] as label}
                <div class="label">{label}</div>
              {/each}
            </div>
            {#each getMonthMatrix(rowIndex * 3 + colIndex, $year) as week}
              <div class="week">
                {#each week as day}
                  {#if day}
                    <div
                      class="day
                        {$holidays.some(h => h.date.toDateString() === day.toDateString()) ? 'holiday' : ''}
                        {$toggledDays.has(day.toDateString()) ? 'toggled' :
                          ($suggestedDaysOff.some(d => d.toDateString() === day.toDateString()) && !$rejectedSuggestions.has(day.toDateString()) ? 'suggested' : '')}
                        {day.getDay() === 6 ? 'saturday' : ''}
                        {day.getDay() === 0 ? 'sunday' : ''}"
                      on:click={() => { if ($isEditing) toggleDay(day); }}
                    >
                      {day.getDate()}
                    </div>
                  {:else}
                    <div class="day"></div>
                  {/if}
                {/each}
              </div>
            {/each}
          </div>
        {/if}
      {/each}
    </div>
  {/each}
</div>

<footer class="footer">
  <p>Made by Rafael Falcão 🦅 and ChatGPT-4o</p>
</footer>

