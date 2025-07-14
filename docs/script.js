document.addEventListener('DOMContentLoaded', function() {
  const nav = document.querySelector('nav');

  // Crear botón hamburguesa dinámicamente
  const menuToggle = document.createElement('div');
  menuToggle.classList.add('menu-toggle');

  for (let i = 0; i < 3; i++) {
    const bar = document.createElement('div');
    menuToggle.appendChild(bar);
  }

  document.querySelector('header').appendChild(menuToggle);

  menuToggle.addEventListener('click', function() {
    nav.classList.toggle('active');
  });
  
  // Cerrar menú al hacer clic en un enlace
  nav.querySelectorAll('a').forEach(link => {
    link.addEventListener('click', function() {
      nav.classList.remove('active');
    });
  });

  // Cerrar menú al hacer clic fuera
  document.addEventListener('click', function(e) {
    if (!nav.contains(e.target) && !menuToggle.contains(e.target)) {
      nav.classList.remove('active');
    }
  });

  // Limpia hash al seleccionar menú y realiza desplazamiento suave hace la sección
  document.querySelectorAll('nav a').forEach(link => {
	link.addEventListener('click', function(e) {
	  // Smooth scroll con comportamiento nativo
	  e.preventDefault();
	  const targetId = this.getAttribute('href').substring(1);
	  const targetElement = document.getElementById(targetId);

	  window.scrollTo({
		top: targetElement.offsetTop - 60,
		behavior: 'smooth'
	  });

	  // Limpiar hash en URL
	  history.pushState(null, null, ' ');
	});
  });

});