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

  const countryNames = new Intl.DisplayNames(['en'], { type: 'region' });
  function countryFlagEmoji(code: string): string {
    return code
      .toUpperCase()
      .replace(/./g, char => String.fromCodePoint(127397 + char.charCodeAt(0)));
  }

  $: if (selectedCountry && ptoData[$selectedCountry]) {
    ptoDays.set(ptoData[$selectedCountry]);
    updateHolidays($year, $selectedCountry);
  }

  async function updateHolidays(y: number, country: string) {
    const holidayList = getHolidaysForYear(country, y);
    holidays.set(holidayList.map(h => ({ date: new Date(h.date) })));
  }

  function recalculateSuggestions() {
    const optimized = optimizeDaysOff($holidays.map(h => ({ date: new Date(h.date) })), $year, $ptoDays);
    suggestedDaysOff.set(optimized);
    if (!$isEditing) toggledDays.set(new Set());
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
  const totalDaysOff = derived([toggledDays, holidays], ([$toggled, $holidays]) => {
    const seen = new Set();
    for (let d = new Date($year, 0, 1); d.getFullYear() === $year; d.setDate(d.getDate() + 1)) {
      const dateStr = new Date(d).toDateString();
      if ([...$toggled].includes(dateStr) || $holidays.find(h => h.date.toDateString() === dateStr) || d.getDay() === 0 || d.getDay() === 6) {
        seen.add(dateStr);
      }
    }
    return seen.size;
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
  }
  function decrementPTO() {
    ptoDays.update(n => Math.max(0, n - 1));
  }
</script>

<style>
  :global(body) {
    background-color: #0b1d3a;
    color: #ffffff;
    font-family: sans-serif;
    margin: 0;
    padding: 2rem;
  }
  .controls {
    display: flex;
    flex-wrap: wrap;
    gap: 1rem;
    justify-content: center;
    align-items: center;
    margin-bottom: 1rem;
  }
  .calendar-container {
    display: flex;
    flex-direction: column;
    gap: 2rem;
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
    margin-bottom: 0.5rem;
    font-size: 1.25rem;
  }
  .week-labels, .week {
    display: grid;
    grid-template-columns: repeat(7, 2rem);
    gap: 0.25rem;
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
    width: 2rem;
    height: 2rem;
    text-align: center;
    line-height: 2rem;
    border: 1px solid rgba(255, 255, 255, 0.1);
    border-radius: 4px;
    cursor: pointer;
  }
  .holiday {
    background-color: orange;
  }
  .suggested {
    background-color: #caffbf;
    color: #000;
  }
  .toggled {
    background-color: #1f6feb !important;
    color: white;
  }
  .saturday {
    background-color: #374151;
  }
  .sunday {
    background-color: #4b5563;
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
  .pto-selector {
    display: flex;
    justify-content: center;
    margin-top: 1.5rem;
  }
  .button {
    padding: 0.4rem 0.8rem;
    background: #1f6feb;
    color: white;
    border: none;
    border-radius: 4px;
    cursor: pointer;
    font-weight: 500;
    transition: background 0.2s ease-in-out;
  }
  .button:hover {
    background: #1158c7;
  }
  .button:disabled {
    background: #999;
    cursor: not-allowed;
  }
</style>


<section class="hero">
  <h1>🎯 Holiday Time Hacker</h1>
  <p>
    In {countryFlagEmoji($selectedCountry)} <strong>{countryNames.of($selectedCountry)}</strong>,
    you’ve got <strong>{$ptoDays} days off</strong> and <strong>{$holidays.length} public holidays</strong> in <strong>{$year}</strong>.
  </p>
  <p>
    Let’s hack your calendar to unlock <strong>{$totalDaysOff} non-working days</strong>.
  </p>
</section>

<div class="controls">
  <select bind:value={$selectedCountry}>
    {#each Object.keys(ptoData).sort() as code}
      <option value={code}>{countryNames.of(code)} {countryFlagEmoji(code)}</option>
    {/each}
  </select>

  <button on:click={() => year.update(y => y - 1)} disabled={$year <= currentYear}>◀ {$year - 1}</button>
  <strong class="text-white text-lg">{$year}</strong>
  <button on:click={() => year.update(y => y + 1)} disabled={$year >= currentYear + 10}>{$year + 1} ▶</button>
</div>

<div class="pto-selector">
  <div class="text-center">
    <label for="ptoDays" class="block text-sm font-medium text-white mb-2">
      PTO Days <span title="📅 Paid Time Off – Number of vacation days you want to use this year." class="ml-1 cursor-help">📅</span>
    </label>
    <div class="flex items-center justify-center">
      <button type="button" on:click={decrementPTO} class="px-4 py-2 rounded-l-md bg-blue-500 text-white hover:bg-blue-600 focus:outline-none">–</button>
      <span class="w-16 text-center bg-white text-black border-y border-gray-300 py-2">{$ptoDays}</span>
      <button type="button" on:click={incrementPTO} class="px-4 py-2 rounded-r-md bg-blue-500 text-white hover:bg-blue-600 focus:outline-none">+</button>
    </div>
    {#if ptoError}
      <p class="text-sm text-red-500 mt-2">{ptoError}</p>
    {/if}
  </div>
</div>

<p style="text-align: center;">Used PTO Days: {$usedPTO} / {$ptoDays}</p>
<p style="text-align: center;">Total Days Off (holidays + weekends + PTO): {$totalDaysOff}</p>

<div class="controls">
  <button on:click={applySuggestedDays}>✏️ Edit Suggested PTO</button>
  <button on:click={recalculateSuggestions}>🔄 Calculate</button>
  {#if $isEditing}
    <button on:click={cancelEdits}>❌ Cancel Edits</button>
  {/if}
  <button on:click={clearAllSelections}>🧹 Clear Calendar</button>
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

<section class="hero">
  <p>
    This app helps you get the most out of your paid time off by automatically finding the best days
    to take off around public holidays and weekends. It uses smart calendar analysis to show you how
    to turn a few PTO days into extended breaks—no guesswork, no wasted days.
  </p>
</section>

<footer class="footer">
  <p>Made by Rafael Falcão 🦅 and ChatGPT-4o</p>
</footer>
