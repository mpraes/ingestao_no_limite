/* ============================================================
   dashboard.js — State management, data loading, filters, KPIs
   ============================================================ */

// ─── App State ───────────────────────────────────────────────
const state = {
  rawData: [],
  filteredData: [],
  filters: {
    categorias: [],   // array de strings selecionadas ([] = todas)
    vendedor:  '',
    estado:    '',
    mesDe:     '',
    mesAte:    '',
  },
};

const tip = document.getElementById('tooltip');
const MESES = ['Jan','Fev','Mar','Abr','Mai','Jun','Jul','Ago','Set','Out','Nov','Dez'];

// ─── Data Loading ─────────────────────────────────────────────
Papa.parse('./vendas_desafio.csv', {
  download: true,
  header: true,
  dynamicTyping: true,
  skipEmptyLines: true,
  complete({ data }) {
    // Enrich: faturamento, mes
    state.rawData = data.map(d => ({
      ...d,
      preco:       +d.preco_unitario || 0,
      qtd:         +d.quantidade     || 0,
      faturamento: +d.preco_unitario * +d.quantidade,
      mes:         (d.data_venda || '').slice(0, 7), // 'YYYY-MM'
    })).filter(d => d.faturamento > 0);

    buildFilters();
    applyFilters();

    document.getElementById('loading').style.display = 'none';
    document.getElementById('dashboard').style.display = 'block';
    updateHeaderMeta();
  },
  error(err) {
    document.getElementById('loading').innerHTML =
      `<div class="empty">❌ Erro ao carregar CSV: ${err.message}</div>`;
  }
});

// ─── Build Filter UI ─────────────────────────────────────────
function buildFilters() {
  const data = state.rawData;
  const categorias = [...new Set(data.map(d => d.categoria))].sort();
  const vendedores = [...new Set(data.map(d => d.vendedor))].sort();
  const estados    = [...new Set(data.map(d => d.estado))].sort();
  const meses      = [...new Set(data.map(d => d.mes))].sort();

  // Chips – categorias
  const chipGroup = document.getElementById('chip-categoria');
  chipGroup.innerHTML = '';
  categorias.forEach(cat => {
    const btn = document.createElement('button');
    btn.className = 'chip';
    btn.textContent = cat;
    btn.dataset.cat = cat;
    btn.addEventListener('click', () => toggleCategoria(cat, btn));
    chipGroup.appendChild(btn);
  });

  // Select – vendedor
  const selV = document.getElementById('sel-vendedor');
  selV.innerHTML = '<option value="">Todos</option>';
  vendedores.forEach(v => {
    const o = document.createElement('option');
    o.value = v; o.textContent = v;
    selV.appendChild(o);
  });
  selV.addEventListener('change', () => {
    state.filters.vendedor = selV.value;
    applyFilters();
  });

  // Select – estado
  const selE = document.getElementById('sel-estado');
  selE.innerHTML = '<option value="">Todos</option>';
  estados.forEach(e => {
    const o = document.createElement('option');
    o.value = e; o.textContent = e;
    selE.appendChild(o);
  });
  selE.addEventListener('change', () => {
    state.filters.estado = selE.value;
    applyFilters();
  });

  // Selects – período
  const selDe  = document.getElementById('sel-mes-de');
  const selAte = document.getElementById('sel-mes-ate');
  selDe.innerHTML = '<option value="">—</option>';
  selAte.innerHTML = '<option value="">—</option>';
  meses.forEach(m => {
    const label = formatMes(m);
    [selDe, selAte].forEach(sel => {
      const o = document.createElement('option'); o.value = m; o.textContent = label;
      sel.appendChild(o);
    });
  });
  selDe.addEventListener('change', () => { state.filters.mesDe = selDe.value; applyFilters(); });
  selAte.addEventListener('change', () => { state.filters.mesAte = selAte.value; applyFilters(); });

  // Btn reset
  document.getElementById('btn-reset').addEventListener('click', resetFilters);
}

// ─── Filter Helpers ───────────────────────────────────────────
function toggleCategoria(cat, el) {
  const f = state.filters.categorias;
  const idx = f.indexOf(cat);
  if (idx === -1) { f.push(cat); el.classList.add('active'); }
  else { f.splice(idx, 1); el.classList.remove('active'); }
  applyFilters();
}

function resetFilters() {
  state.filters = { categorias: [], vendedor: '', estado: '', mesDe: '', mesAte: '' };
  document.querySelectorAll('.chip').forEach(c => c.classList.remove('active'));
  document.getElementById('sel-vendedor').value = '';
  document.getElementById('sel-estado').value = '';
  document.getElementById('sel-mes-de').value = '';
  document.getElementById('sel-mes-ate').value = '';
  applyFilters();
}

// ─── Apply Filters + Render ───────────────────────────────────
function applyFilters() {
  const { categorias, vendedor, estado, mesDe, mesAte } = state.filters;
  state.filteredData = state.rawData.filter(d => {
    if (categorias.length && !categorias.includes(d.categoria)) return false;
    if (vendedor && d.vendedor !== vendedor) return false;
    if (estado  && d.estado  !== estado)    return false;
    if (mesDe   && d.mes < mesDe)           return false;
    if (mesAte  && d.mes > mesAte)          return false;
    return true;
  });
  renderDashboard();
}

// ─── Render Orchestrator ──────────────────────────────────────
function renderDashboard() {
  const data = state.filteredData;

  updateKPIs(data);

  // Cross-filter callback from categoria bar
  const onCatClick = (cat) => {
    const chipEl = document.querySelector(`.chip[data-cat="${cat}"]`);
    toggleCategoria(cat, chipEl);
  };

  drawBarCategoria(data, 'chart-categoria', tip, onCatClick);
  drawLineTrend(data, 'chart-trend', tip);
  drawDonut(data, 'chart-donut', 'legend-donut', tip);
  drawBarProdutos(data, 'chart-produtos', tip);
  drawStackedVendedor(data, 'chart-vendedor', 'legend-vendedor', tip);
  drawClienteTable(data, 'chart-clientes');
}

// ─── KPI Updater ──────────────────────────────────────────────
function updateKPIs(data) {
  const fat     = d3.sum(data, d => d.faturamento);
  const vendas  = data.length;
  const clientes = new Set(data.map(d => d.cliente)).size;
  const ticket  = vendas > 0 ? fat / vendas : 0;

  // Top categoria
  const topCat = d3.rollups(data, v => d3.sum(v, d => d.faturamento), d => d.categoria)
    .sort((a,b) => b[1]-a[1])[0];

  animateCounter('kpi-fat',      fat,     'brl');
  animateCounter('kpi-vendas',   vendas,  'num');
  animateCounter('kpi-clientes', clientes,'num');
  animateCounter('kpi-ticket',   ticket,  'brl');

  document.getElementById('kpi-fat-badge').textContent =
    topCat ? `▲ ${topCat[0]} lidera` : '';
  document.getElementById('kpi-vendas-sub').textContent =
    `${data.length.toLocaleString('pt-BR')} transações filtradas`;
  document.getElementById('kpi-clientes-sub').textContent =
    `100% clientes recorrentes`;
  document.getElementById('kpi-ticket-sub').textContent =
    `por transação`;
}

function animateCounter(id, target, type) {
  const el = document.getElementById(id);
  const duration = 800;
  const start = performance.now();
  const startVal = parseFloat(el.dataset.current || 0) || 0;
  el.dataset.current = target;

  function tick(now) {
    const t = Math.min((now - start) / duration, 1);
    const ease = 1 - Math.pow(1 - t, 3); // ease out cubic
    const val = startVal + (target - startVal) * ease;
    el.textContent = type === 'brl' ? fmt.brl(val) : Math.round(val).toLocaleString('pt-BR');
    if (t < 1) requestAnimationFrame(tick);
  }
  requestAnimationFrame(tick);
}

// ─── Header Meta ─────────────────────────────────────────────
function updateHeaderMeta() {
  const total = state.rawData.length;
  const meses = new Set(state.rawData.map(d => d.mes)).size;
  document.getElementById('header-meta').textContent =
    `${total.toLocaleString('pt-BR')} registros · ${meses} meses · Atualizado ao filtrar`;
}

// ─── Helpers ──────────────────────────────────────────────────
function formatMes(mes) {
  if (!mes) return '';
  const [year, month] = mes.split('-');
  return `${MESES[+month - 1]}/${year.slice(2)}`;
}

// ─── Resize Responsiveness ────────────────────────────────────
let resizeTimer;
window.addEventListener('resize', () => {
  clearTimeout(resizeTimer);
  resizeTimer = setTimeout(() => {
    if (state.filteredData.length) renderDashboard();
  }, 200);
});
