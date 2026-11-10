import { test } from 'node:test';
import assert from 'node:assert/strict';

import { parsePrice } from '../src/parse-price.js';

test('converte formato brasileiro com milhar e centavos', () => {
  assert.equal(parsePrice('R$ 1.234,56'), 123456);
});

test('converte sem prefixo R$ e sem separador de milhar', () => {
  assert.equal(parsePrice('1234,56'), 123456);
});

test('converte inteiro colado ao prefixo', () => {
  assert.equal(parsePrice('R$10'), 1000);
});

test('converte um único dígito de centavo', () => {
  assert.equal(parsePrice('10,5'), 1050);
});

test('resultado é inteiro sem erro de ponto flutuante', () => {
  assert.equal(parsePrice('0,29'), 29);
  assert.equal(parsePrice('1,1'), 110);
  assert.ok(Number.isInteger(parsePrice('19,99')));
});

test('aceita exatamente o limite seguro de centavos (CX-01)', () => {
  assert.equal(parsePrice('90071992547409,91'), Number.MAX_SAFE_INTEGER);
});

test('valor acima do limite seguro lança RangeError em vez de perder precisão (CX-01)', () => {
  assert.throws(() => parsePrice('90071992547409,92'), RangeError);
  assert.throws(() => parsePrice('90071992547409,93'), RangeError);
  assert.throws(() => parsePrice('9'.repeat(309)), RangeError);
});

test('entrada que não é preço lança TypeError', () => {
  assert.throws(() => parsePrice('abc'), TypeError);
  assert.throws(() => parsePrice(''), TypeError);
  assert.throws(() => parsePrice(null), TypeError);
});
