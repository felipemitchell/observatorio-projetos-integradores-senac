/* ============================================================
   SENAC — Observatório de Projetos | app.js
   Controla autenticação, roteamento e logout
   ============================================================ */

const USERS = {
  'aluno@senac.br':     { senha: 'aluno123',  perfil: 'aluno',     nome: 'João Silva',       iniciais: 'JS', role: 'Aluno' },
  'professor@senac.br': { senha: 'prof123',   perfil: 'professor', nome: 'Carlos Silva',     iniciais: 'CS', role: 'Professor' },
  'admin@senac.br':     { senha: 'admin123',  perfil: 'admin',     nome: 'Ana Coordenadora', iniciais: 'AC', role: 'Coordenadora' },
};

let usuarioLogado = null;

/* ---------- utilitários ---------- */
function mostrarPagina(id) {
  document.querySelectorAll('.page').forEach(p => p.classList.remove('active'));
  const pg = document.getElementById(id);
  if (pg) pg.classList.add('active');
  window.scrollTo(0, 0);
}

function preencherTopbar(pagina) {
  if (!usuarioLogado) return;
  const u = usuarioLogado;

  const nome     = pagina.querySelector('.topbar-nome');
  const role     = pagina.querySelector('.topbar-role');
  const avatar   = pagina.querySelector('.topbar-avatar');

  if (nome)   nome.textContent   = u.nome;
  if (role)   role.textContent   = u.role;
  if (avatar) {
    avatar.textContent = u.iniciais;
    avatar.className   = 'avatar ' + (u.perfil === 'admin' ? 'orange' : u.perfil === 'professor' ? 'mid' : 'navy');
  }
}

/* ---------- LOGIN ---------- */
document.getElementById('form-login').addEventListener('submit', function(e) {
  e.preventDefault();

  const email = document.getElementById('email').value.trim().toLowerCase();
  const senha = document.getElementById('senha').value;
  const erro  = document.getElementById('login-erro');

  const user = USERS[email];

  if (!user || user.senha !== senha) {
    erro.classList.add('visible');
    return;
  }

  erro.classList.remove('visible');
  usuarioLogado = user;

  const destino = 'page-' + user.perfil;
  const pg = document.getElementById(destino);
  preencherTopbar(pg);
  mostrarPagina(destino);
});

document.getElementById('email').addEventListener('input', () => {
  document.getElementById('login-erro').classList.remove('visible');
});

/* ---------- LOGOUT (todos os dashboards) ---------- */
document.querySelectorAll('.logout-btn').forEach(btn => {
  btn.addEventListener('click', () => {
    usuarioLogado = null;
    document.getElementById('form-login').reset();
    mostrarPagina('page-login');
  });
});

/* ---------- inicializa na tela de login ---------- */
mostrarPagina('page-login');
