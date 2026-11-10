// Formato brasileiro: prefixo R$ opcional, milhar com ponto opcional, centavos com vírgula (1 ou 2 dígitos).
const BR_PRICE = /^(?:R\$\s*)?(\d{1,3}(?:\.\d{3})+|\d+)(?:,(\d{1,2}))?$/;

export const parsePrice = (text) => {
  if (typeof text !== 'string') {
    throw new TypeError(`parsePrice espera string, recebeu ${text === null ? 'null' : typeof text}`);
  }

  const match = BR_PRICE.exec(text.trim());
  if (!match) {
    throw new TypeError(`parsePrice: "${text}" não é um preço em reais`);
  }

  const reais = match[1].replace(/\./g, '');
  const centavos = (match[2] ?? '').padEnd(2, '0');

  // BigInt: aritmética exata; Number só depois de garantir que cabe sem perder centavo.
  const totalCentavos = BigInt(reais) * 100n + BigInt(centavos);
  if (totalCentavos > BigInt(Number.MAX_SAFE_INTEGER)) {
    throw new RangeError(`parsePrice: "${text}" excede o valor máximo representável em centavos`);
  }

  return Number(totalCentavos);
};
