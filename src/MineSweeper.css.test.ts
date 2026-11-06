import { readFileSync } from 'node:fs';
import { resolve } from 'node:path';

// The stylesheet ships to every page that embeds the component, unlayered. A
// selector outside the component's root restyles the host page: the old global
// `*` reset stripped the padding from noracasey.com's project pages (MINE-25).
describe('MineSweeper.css', () => {
  const css = readFileSync(resolve(process.cwd(), 'src/MineSweeper.css'), 'utf8').replace(
    /\/\*[\s\S]*?\*\//g,
    '',
  );

  const selectors = [...css.matchAll(/([^{}]+)\{/g)].flatMap((match) =>
    match[1].split(',').map((selector) => selector.trim()),
  );

  it('has rules to check', () => {
    expect(selectors.length).toBeGreaterThan(10);
  });

  it.each(selectors)('scopes "%s" to the game', (selector) => {
    expect(selector).toMatch(/^\.game(?![\w-])/);
  });
});
