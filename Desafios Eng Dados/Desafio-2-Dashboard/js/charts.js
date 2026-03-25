/* ============================================================
   charts.js — 6 D3.js chart functions
   Each function receives (data, containerId, tooltip)
   ============================================================ */

const COLORS = {
  cat: {
    'Eletrônicos': '#6366f1',
    'Móveis':      '#10b981',
    'Livros':      '#f59e0b',
    'Acessórios':  '#38bdf8',
  },
  seq: ['#6366f1','#10b981','#f59e0b','#38bdf8','#ef4444'],
};

const fmt = {
  brl:  v => 'R$ ' + v.toLocaleString('pt-BR', {minimumFractionDigits:0, maximumFractionDigits:0}),
  brlk: v => v >= 1e6 ? `R$ ${(v/1e6).toFixed(1)}M` : v >= 1e3 ? `R$ ${(v/1e3).toFixed(0)}K` : `R$ ${v.toFixed(0)}`,
  num:  v => v.toLocaleString('pt-BR'),
  pct:  v => v.toFixed(1) + '%',
};

// ─── Shared tooltip helpers ───────────────────────────────────
function showTip(tip, html, event) {
  tip.innerHTML = html;
  tip.classList.add('visible');
  moveTip(tip, event);
}
function moveTip(tip, event) {
  const x = event.pageX + 14;
  const y = event.pageY - 10;
  tip.style.left = x + 'px';
  tip.style.top  = y + 'px';
}
function hideTip(tip) { tip.classList.remove('visible'); }

// ─── 1. Vertical Bar: Faturamento por Categoria ──────────────
function drawBarCategoria(data, containerId, tip, onCategoryClick) {
  const el = document.getElementById(containerId);
  el.innerHTML = '';
  if (!data.length) { el.innerHTML = '<div class="empty">Sem dados</div>'; return; }

  const margin = {top: 20, right: 20, bottom: 36, left: 80};
  const W = el.clientWidth || 800;
  const H = 220;
  const w = W - margin.left - margin.right;
  const h = H - margin.top - margin.bottom;

  const svg = d3.select(el).append('svg')
    .attr('width', W).attr('height', H).attr('class', 'chart-svg');

  const g = svg.append('g').attr('transform', `translate(${margin.left},${margin.top})`);

  const grouped = d3.rollups(data, v => d3.sum(v, d => d.faturamento), d => d.categoria)
    .map(([categoria, total]) => ({ categoria, total }))
    .sort((a,b) => b.total - a.total);

  const x = d3.scaleBand().domain(grouped.map(d => d.categoria)).range([0, w]).padding(0.25);
  const y = d3.scaleLinear().domain([0, d3.max(grouped, d => d.total) * 1.1]).range([h, 0]);

  // Grid lines
  g.append('g').attr('class','grid')
    .call(d3.axisLeft(y).ticks(4).tickSize(-w).tickFormat(''))
    .select('.domain').remove();

  // X axis
  g.append('g').attr('transform', `translate(0,${h})`)
    .call(d3.axisBottom(x).tickSize(0))
    .call(ax => ax.select('.domain').remove());

  // Y axis
  g.append('g').call(d3.axisLeft(y).ticks(4).tickFormat(fmt.brlk))
    .call(ax => ax.select('.domain').remove());

  // Bars
  const bars = g.selectAll('.bar').data(grouped).join('rect')
    .attr('class', 'bar')
    .attr('x', d => x(d.categoria))
    .attr('width', x.bandwidth())
    .attr('y', h).attr('height', 0)
    .attr('rx', 6)
    .attr('fill', d => COLORS.cat[d.categoria] || COLORS.seq[0])
    .attr('opacity', 0.85)
    .style('cursor', 'pointer');

  // Animate in
  bars.transition().duration(600).ease(d3.easeCubicOut)
    .attr('y', d => y(d.total))
    .attr('height', d => h - y(d.total));

  // Value labels
  g.selectAll('.bar-label').data(grouped).join('text')
    .attr('class', 'bar-label')
    .attr('x', d => x(d.categoria) + x.bandwidth()/2)
    .attr('y', d => y(d.total) - 6)
    .attr('text-anchor', 'middle')
    .attr('font-size', 11).attr('font-weight', 600)
    .attr('fill', 'var(--text-secondary)')
    .attr('opacity', 0)
    .text(d => fmt.brlk(d.total))
    .transition().delay(400).duration(300).attr('opacity', 1);

  // Interactions
  bars.on('mouseover', (event, d) => {
    d3.select(event.target).attr('opacity', 1).attr('filter', 'brightness(1.2)');
    const total = d3.sum(data, r => r.faturamento);
    showTip(tip,
      `<div class="tooltip-label">${d.categoria}</div>
       <div class="tooltip-row">Faturamento: <span>${fmt.brl(d.total)}</span></div>
       <div class="tooltip-row">Participação: <span>${fmt.pct(d.total/total*100)}</span></div>`,
      event);
  })
  .on('mousemove', (event) => moveTip(tip, event))
  .on('mouseout', (event) => {
    d3.select(event.target).attr('opacity', 0.85).attr('filter', null);
    hideTip(tip);
  })
  .on('click', (event, d) => {
    if (onCategoryClick) onCategoryClick(d.categoria);
  });
}

// ─── 2. Line Chart: Tendência Mensal ─────────────────────────
function drawLineTrend(data, containerId, tip) {
  const el = document.getElementById(containerId);
  el.innerHTML = '';
  if (!data.length) { el.innerHTML = '<div class="empty">Sem dados</div>'; return; }

  const margin = {top: 16, right: 20, bottom: 40, left: 80};
  const W = el.clientWidth || 600;
  const H = 220;
  const w = W - margin.left - margin.right;
  const h = H - margin.top - margin.bottom;

  const svg = d3.select(el).append('svg')
    .attr('width', W).attr('height', H).attr('class', 'chart-svg');
  const g = svg.append('g').attr('transform', `translate(${margin.left},${margin.top})`);

  // Aggregate by month
  const monthly = d3.rollups(data,
    v => ({fat: d3.sum(v, d => d.faturamento), count: v.length}),
    d => d.mes)
    .map(([mes, v]) => ({mes, ...v}))
    .sort((a,b) => a.mes.localeCompare(b.mes));

  const parseM = d3.timeParse('%Y-%m');
  monthly.forEach(d => { d.date = parseM(d.mes); });

  const x = d3.scaleTime().domain(d3.extent(monthly, d => d.date)).range([0, w]);
  const y = d3.scaleLinear().domain([0, d3.max(monthly, d => d.fat) * 1.1]).range([h, 0]);

  // Grid
  g.append('g').attr('class','grid')
    .call(d3.axisLeft(y).ticks(4).tickSize(-w).tickFormat(''))
    .select('.domain').remove();

  // Axes
  g.append('g').attr('transform', `translate(0,${h})`)
    .call(d3.axisBottom(x).ticks(d3.timeMonth.every(1)).tickFormat(d3.timeFormat('%b')))
    .call(ax => ax.select('.domain').remove());
  g.append('g').call(d3.axisLeft(y).ticks(4).tickFormat(fmt.brlk))
    .call(ax => ax.select('.domain').remove());

  // Area
  const area = d3.area().x(d => x(d.date)).y0(h).y1(d => y(d.fat)).curve(d3.curveMonotoneX);
  g.append('path').datum(monthly)
    .attr('fill', 'url(#area-grad)').attr('d', area).attr('opacity', 0.15);

  // Gradient def
  const defs = svg.append('defs');
  const grad = defs.append('linearGradient').attr('id','area-grad')
    .attr('gradientTransform','rotate(90)');
  grad.append('stop').attr('offset','0%').attr('stop-color','#6366f1');
  grad.append('stop').attr('offset','100%').attr('stop-color','#6366f100');

  // Line
  const line = d3.line().x(d => x(d.date)).y(d => y(d.fat)).curve(d3.curveMonotoneX);
  const path = g.append('path').datum(monthly)
    .attr('fill','none').attr('stroke','#6366f1').attr('stroke-width',2.5)
    .attr('d', line);

  // Animate line draw
  const pathLen = path.node().getTotalLength();
  path.attr('stroke-dasharray', pathLen).attr('stroke-dashoffset', pathLen)
    .transition().duration(900).ease(d3.easeCubicOut)
    .attr('stroke-dashoffset', 0);

  // Dots
  g.selectAll('.dot').data(monthly).join('circle')
    .attr('class','dot').attr('cx', d => x(d.date)).attr('cy', d => y(d.fat))
    .attr('r', 4).attr('fill','#6366f1').attr('stroke','var(--bg-primary)').attr('stroke-width',2)
    .on('mouseover', (event, d) => {
      d3.select(event.target).attr('r', 6);
      showTip(tip,
        `<div class="tooltip-label">${d3.timeFormat('%B %Y')(d.date)}</div>
         <div class="tooltip-row">Faturamento: <span>${fmt.brl(d.fat)}</span></div>
         <div class="tooltip-row">Nº Vendas: <span>${fmt.num(d.count)}</span></div>`,
        event);
    })
    .on('mousemove', (event) => moveTip(tip, event))
    .on('mouseout', (event) => { d3.select(event.target).attr('r', 4); hideTip(tip); });
}

// ─── 3. Donut: % Participação por Categoria ──────────────────
function drawDonut(data, containerId, legendId, tip) {
  const el = document.getElementById(containerId);
  el.innerHTML = '';
  const leg = document.getElementById(legendId);
  leg.innerHTML = '';
  if (!data.length) { el.innerHTML = '<div class="empty">Sem dados</div>'; return; }

  const W = el.clientWidth || 280;
  const H = 200;
  const radius = Math.min(W, H) / 2 - 16;

  const svg = d3.select(el).append('svg')
    .attr('width', W).attr('height', H).attr('class','chart-svg');
  const g = svg.append('g').attr('transform', `translate(${W/2},${H/2})`);

  const grouped = d3.rollups(data, v => d3.sum(v, d => d.faturamento), d => d.categoria)
    .map(([categoria, value]) => ({categoria, value}))
    .sort((a,b) => b.value - a.value);
  const total = d3.sum(grouped, d => d.value);

  const pie = d3.pie().value(d => d.value).sort(null).padAngle(0.03);
  const arc = d3.arc().innerRadius(radius * 0.55).outerRadius(radius);
  const arcHover = d3.arc().innerRadius(radius * 0.55).outerRadius(radius + 6);

  const slices = g.selectAll('.slice').data(pie(grouped)).join('path')
    .attr('class','slice')
    .attr('fill', d => COLORS.cat[d.data.categoria] || '#888')
    .attr('d', arc)
    .style('cursor','pointer')
    .attr('opacity', 0.85);

  slices.transition().duration(700).ease(d3.easeCubicOut)
    .attrTween('d', function(d) {
      const i = d3.interpolate({startAngle: 0, endAngle: 0}, d);
      return t => arc(i(t));
    });

  // Center text
  const center = g.append('g');
  center.append('text').attr('text-anchor','middle').attr('dy','-0.2em')
    .attr('font-size',11).attr('fill','var(--text-muted)').text('Total');
  center.append('text').attr('text-anchor','middle').attr('dy','1em')
    .attr('font-size',13).attr('font-weight',700).attr('fill','var(--text-primary)')
    .text(fmt.brlk(total));

  slices.on('mouseover', (event, d) => {
    d3.select(event.target).attr('d', arcHover).attr('opacity',1);
    showTip(tip,
      `<div class="tooltip-label">${d.data.categoria}</div>
       <div class="tooltip-row">Faturamento: <span>${fmt.brl(d.data.value)}</span></div>
       <div class="tooltip-row">Participação: <span>${fmt.pct(d.data.value/total*100)}</span></div>`,
      event);
  })
  .on('mousemove', (event) => moveTip(tip, event))
  .on('mouseout', (event, d) => { d3.select(event.target).attr('d', arc).attr('opacity',0.85); hideTip(tip); });

  // Legend
  grouped.forEach(d => {
    leg.innerHTML += `
      <div class="legend-item">
        <div class="legend-dot" style="background:${COLORS.cat[d.categoria]||'#888'}"></div>
        <span>${d.categoria} (${fmt.pct(d.value/total*100)})</span>
      </div>`;
  });
}

// ─── 4. Horizontal Bar: Top Produtos ─────────────────────────
function drawBarProdutos(data, containerId, tip) {
  const el = document.getElementById(containerId);
  el.innerHTML = '';
  if (!data.length) { el.innerHTML = '<div class="empty">Sem dados</div>'; return; }

  const margin = {top: 8, right: 80, bottom: 8, left: 100};
  const produtos = d3.rollups(data, v => d3.sum(v, d => d.faturamento), d => d.produto)
    .map(([produto, fat]) => ({produto, fat}))
    .sort((a,b) => b.fat - a.fat).slice(0, 10);

  const H = Math.max(produtos.length * 30 + margin.top + margin.bottom, 200);
  const W = el.clientWidth || 400;
  const w = W - margin.left - margin.right;
  const h = H - margin.top - margin.bottom;

  const svg = d3.select(el).append('svg').attr('width',W).attr('height',H).attr('class','chart-svg');
  const g = svg.append('g').attr('transform',`translate(${margin.left},${margin.top})`);

  const y = d3.scaleBand().domain(produtos.map(d => d.produto)).range([0, h]).padding(0.25);
  const x = d3.scaleLinear().domain([0, d3.max(produtos, d => d.fat) * 1.08]).range([0, w]);

  g.append('g').call(d3.axisLeft(y).tickSize(0))
    .call(ax => ax.select('.domain').remove())
    .selectAll('text').attr('font-size',11).attr('fill','var(--text-secondary)');

  const bars = g.selectAll('.bar').data(produtos).join('rect')
    .attr('y', d => y(d.produto)).attr('height', y.bandwidth())
    .attr('x', 0).attr('width', 0).attr('rx', 4)
    .attr('fill', (d,i) => COLORS.seq[i % COLORS.seq.length]).attr('opacity',0.85);

  bars.transition().duration(600).ease(d3.easeCubicOut)
    .attr('width', d => x(d.fat));

  // Value labels
  g.selectAll('.val-label').data(produtos).join('text')
    .attr('y', d => y(d.produto) + y.bandwidth()/2 + 4)
    .attr('x', d => x(d.fat) + 6).attr('font-size',11).attr('fill','var(--text-secondary)')
    .attr('opacity',0)
    .text(d => fmt.brlk(d.fat))
    .transition().delay(400).duration(200).attr('opacity',1);

  bars.on('mouseover', (event, d) => {
    d3.select(event.target).attr('opacity',1);
    showTip(tip,
      `<div class="tooltip-label">${d.produto}</div>
       <div class="tooltip-row">Faturamento: <span>${fmt.brl(d.fat)}</span></div>`,
      event);
  })
  .on('mousemove', (event) => moveTip(tip, event))
  .on('mouseout', (event) => { d3.select(event.target).attr('opacity',0.85); hideTip(tip); });
}

// ─── 5. Stacked Bar: Vendedor × Categoria ────────────────────
function drawStackedVendedor(data, containerId, legendId, tip) {
  const el = document.getElementById(containerId);
  el.innerHTML = '';
  const leg = document.getElementById(legendId);
  leg.innerHTML = '';
  if (!data.length) { el.innerHTML = '<div class="empty">Sem dados</div>'; return; }

  const categorias = [...new Set(data.map(d => d.categoria))].sort();
  const vendedores = [...new Set(data.map(d => d.vendedor))].sort();

  // Build matrix: vendedor → {cat: fat}
  const matrix = vendedores.map(v => {
    const row = {vendedor: v};
    categorias.forEach(c => {
      row[c] = d3.sum(data.filter(d => d.vendedor === v && d.categoria === c), d => d.faturamento);
    });
    return row;
  });

  const margin = {top: 16, right: 16, bottom: 70, left: 80};
  const W = el.clientWidth || 400;
  const H = 240;
  const w = W - margin.left - margin.right;
  const h = H - margin.top - margin.bottom;

  const svg = d3.select(el).append('svg').attr('width',W).attr('height',H).attr('class','chart-svg');
  const g = svg.append('g').attr('transform',`translate(${margin.left},${margin.top})`);

  const x = d3.scaleBand().domain(vendedores).range([0,w]).padding(0.25);
  const maxVal = d3.max(matrix, d => d3.sum(categorias, c => d[c]));
  const y = d3.scaleLinear().domain([0, maxVal * 1.05]).range([h, 0]);

  g.append('g').attr('class','grid')
    .call(d3.axisLeft(y).ticks(4).tickSize(-w).tickFormat(''))
    .select('.domain').remove();

  g.append('g').attr('transform',`translate(0,${h})`)
    .call(d3.axisBottom(x).tickSize(0))
    .call(ax => ax.select('.domain').remove())
    .selectAll('text').attr('font-size',11).attr('fill','var(--text-secondary)');

  g.append('g').call(d3.axisLeft(y).ticks(4).tickFormat(fmt.brlk))
    .call(ax => ax.select('.domain').remove());

  const stack = d3.stack().keys(categorias)(matrix);

  stack.forEach((layer, ci) => {
    g.selectAll(`.bar-${ci}`).data(layer).join('rect')
      .attr('class',`bar-${ci}`)
      .attr('x', d => x(d.data.vendedor)).attr('width', x.bandwidth())
      .attr('y', h).attr('height', 0).attr('rx', ci === stack.length-1 ? 4 : 0)
      .attr('fill', COLORS.cat[categorias[ci]] || COLORS.seq[ci])
      .attr('opacity',0.85)
      .transition().duration(600).ease(d3.easeCubicOut)
      .attr('y', d => y(d[1]))
      .attr('height', d => y(d[0]) - y(d[1]));

    g.selectAll(`.bar-${ci}-hit`).data(layer).join('rect')
      .attr('class',`bar-${ci}-hit`)
      .attr('x', d => x(d.data.vendedor)).attr('width', x.bandwidth())
      .attr('y', d => y(d[1])).attr('height', d => y(d[0]) - y(d[1]))
      .attr('fill','transparent').style('cursor','pointer')
      .on('mouseover', (event, d) => {
        showTip(tip,
          `<div class="tooltip-label">${d.data.vendedor}</div>
           <div class="tooltip-row">${categorias[ci]}: <span>${fmt.brl(d[1]-d[0])}</span></div>`,
          event);
      })
      .on('mousemove', (event) => moveTip(tip, event))
      .on('mouseout', () => hideTip(tip));
  });

  // Legend
  categorias.forEach(c => {
    leg.innerHTML += `
      <div class="legend-item">
        <div class="legend-dot" style="background:${COLORS.cat[c]||'#888'}"></div>
        <span>${c}</span>
      </div>`;
  });
}

// ─── 6. Table: Top Clientes ───────────────────────────────────
function drawClienteTable(data, containerId) {
  const el = document.getElementById(containerId);
  el.innerHTML = '';
  if (!data.length) { el.innerHTML = '<div class="empty">Sem dados</div>'; return; }

  const clientes = d3.rollups(data,
    v => ({fat: d3.sum(v, d => d.faturamento), compras: v.length}),
    d => d.cliente)
    .map(([cliente, v]) => ({cliente, ...v}))
    .sort((a,b) => b.fat - a.fat).slice(0, 20);

  const maxFat = clientes[0].fat;

  const table = document.createElement('table');
  table.className = 'data-table';
  table.innerHTML = `
    <thead><tr>
      <th>#</th>
      <th>Cliente</th>
      <th style="text-align:right">Faturamento</th>
      <th style="text-align:right">Compras</th>
      <th style="width:140px">Participação</th>
    </tr></thead>
    <tbody>
    ${clientes.map((d, i) => `
      <tr>
        <td class="rank">${i+1}</td>
        <td>${d.cliente}</td>
        <td class="num">${fmt.brl(d.fat)}</td>
        <td class="num">${d.compras}</td>
        <td>
          <div class="bar-inline" style="width:${Math.round(d.fat/maxFat*100)}%"></div>
        </td>
      </tr>`).join('')}
    </tbody>`;
  el.appendChild(table);
}
