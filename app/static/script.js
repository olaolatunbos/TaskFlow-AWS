const STAGE_LABELS = {
  not_started: 'Not Started',
  in_research: 'In Research',
  on_track: 'On Track',
  complete: 'Complete',
};

const PRIORITY_LABELS = { low: 'Low', medium: 'Medium', high: 'High' };

const state = {
  tasks: [],
  query: '',
  editingId: null,
  draggingId: null,
};

const el = {
  board: document.getElementById('board'),
  search: document.getElementById('search'),
  overlay: document.getElementById('overlay'),
  form: document.getElementById('task-form'),
  modalTitle: document.getElementById('modal-title'),
  modalSubmit: document.getElementById('modal-submit'),
};

document.addEventListener('DOMContentLoaded', () => {
  fetchTasks();

  el.search.addEventListener('input', (event) => {
    state.query = event.target.value.trim().toLowerCase();
    render();
  });

  document.getElementById('new-task').addEventListener('click', () => openModal());
  document.getElementById('modal-close').addEventListener('click', closeModal);
  document.getElementById('modal-cancel').addEventListener('click', closeModal);

  el.overlay.addEventListener('click', (event) => {
    if (event.target === el.overlay) closeModal();
  });

  document.addEventListener('keydown', (event) => {
    if (event.key === 'Escape' && !el.overlay.hidden) closeModal();
  });

  el.form.addEventListener('submit', submitTask);

  document.querySelectorAll('[data-add]').forEach((button) => {
    button.addEventListener('click', () => openModal(null, button.dataset.add));
  });

  document.querySelectorAll('.tab').forEach((tab) => {
    tab.addEventListener('click', () => {
      document.querySelectorAll('.tab').forEach((other) => {
        other.classList.toggle('is-active', other === tab);
        other.setAttribute('aria-selected', String(other === tab));
      });
    });
  });

  document.querySelectorAll('[data-dropzone]').forEach(wireDropzone);
});

/* ---------- data ---------- */

function fetchTasks() {
  fetch('/tasks')
    .then((response) => response.json())
    .then((data) => {
      state.tasks = data;
      render();
    })
    .catch((error) => console.error('Error fetching tasks:', error));
}

function saveTask(taskId, payload) {
  const isNew = !taskId;
  return fetch(isNew ? '/tasks' : `/tasks/${taskId}`, {
    method: isNew ? 'POST' : 'PUT',
    headers: { 'Content-Type': 'application/json' },
    body: JSON.stringify(payload),
  }).then((response) => {
    if (!response.ok) throw new Error('Failed to save task');
    return response.json();
  });
}

function deleteTask(taskId) {
  fetch(`/tasks/${taskId}`, { method: 'DELETE' })
    .then((response) => {
      if (!response.ok) throw new Error('Failed to delete task');
      return fetchTasks();
    })
    .catch((error) => console.error(error));
}

function persistOrder() {
  return fetch('/tasks/reorder', {
    method: 'POST',
    headers: { 'Content-Type': 'application/json' },
    body: JSON.stringify({ order: state.tasks.map((task) => task.id) }),
  }).catch((error) => console.error(error));
}

/* ---------- render ---------- */

function render() {
  document.querySelectorAll('[data-dropzone]').forEach((zone) => {
    const status = zone.dataset.dropzone;
    const columnTasks = state.tasks.filter((task) => task.status === status);
    const visible = columnTasks.filter(matchesQuery);

    zone.replaceChildren();
    if (!visible.length) {
      const empty = document.createElement('div');
      empty.className = 'empty';
      empty.textContent = columnTasks.length ? 'No matching tasks' : 'No tasks yet';
      zone.appendChild(empty);
    } else {
      visible.forEach((task) => zone.appendChild(renderCard(task)));
    }

    const count = zone.closest('.column').querySelector('[data-count]');
    count.textContent = columnTasks.length;
  });
}

function matchesQuery(task) {
  if (!state.query) return true;
  return `${task.title} ${task.description}`.toLowerCase().includes(state.query);
}

function renderCard(task) {
  const card = document.createElement('article');
  card.className = 'card';
  card.draggable = true;
  card.dataset.id = task.id;

  const top = document.createElement('div');
  top.className = 'card-top';
  top.appendChild(chip('chip chip-' + task.stage, STAGE_LABELS[task.stage] || 'Not Started'));

  const menu = document.createElement('div');
  menu.className = 'card-menu';
  menu.appendChild(iconButton('#i-pencil', 'Edit task', () => openModal(task)));
  menu.appendChild(iconButton('#i-trash', 'Delete task', () => deleteTask(task.id)));
  top.appendChild(menu);
  card.appendChild(top);

  const title = document.createElement('h3');
  title.textContent = task.title;
  card.appendChild(title);

  if (task.description) {
    const desc = document.createElement('p');
    desc.className = 'card-desc';
    desc.textContent = task.description;
    desc.title = task.description;
    card.appendChild(desc);
  }

  const assigneeRow = document.createElement('div');
  assigneeRow.className = 'card-row';
  const assigneeLabel = document.createElement('span');
  assigneeLabel.textContent = 'Assignees :';
  assigneeRow.appendChild(assigneeLabel);

  const avatars = document.createElement('div');
  avatars.className = 'avatars';
  if (task.assignees && task.assignees.length) {
    task.assignees.slice(0, 3).forEach((name) => avatars.appendChild(avatar(name)));
    if (task.assignees.length > 3) {
      const more = document.createElement('span');
      more.className = 'avatar avatar-more';
      more.textContent = `+${task.assignees.length - 3}`;
      avatars.appendChild(more);
    }
  } else {
    const none = document.createElement('span');
    none.textContent = 'Unassigned';
    avatars.appendChild(none);
  }
  assigneeRow.appendChild(avatars);
  card.appendChild(assigneeRow);

  const metaRow = document.createElement('div');
  metaRow.className = 'card-row';
  const due = document.createElement('span');
  due.className = 'due';
  due.appendChild(svgIcon('#i-flag'));
  due.appendChild(document.createTextNode(formatDate(task.due_date)));
  metaRow.appendChild(due);
  metaRow.appendChild(chip('pill pill-' + task.priority, PRIORITY_LABELS[task.priority] || 'Medium'));
  card.appendChild(metaRow);

  const foot = document.createElement('div');
  foot.className = 'card-foot';
  foot.appendChild(meta('#i-comment', `${task.comments} Comments`));
  foot.appendChild(meta('#i-link', `${task.links} Links`));
  foot.appendChild(meta('#i-checklist', `${task.subtasks_done}/${task.subtasks_total}`));
  card.appendChild(foot);

  card.addEventListener('dblclick', () => openModal(task));
  card.addEventListener('dragstart', (event) => {
    state.draggingId = task.id;
    card.classList.add('is-dragging');
    event.dataTransfer.effectAllowed = 'move';
    event.dataTransfer.setData('text/plain', task.id);
  });
  card.addEventListener('dragend', () => {
    state.draggingId = null;
    card.classList.remove('is-dragging');
  });

  return card;
}

/* ---------- element helpers ---------- */

function svgIcon(href) {
  const svg = document.createElementNS('http://www.w3.org/2000/svg', 'svg');
  svg.setAttribute('class', 'icon');
  const use = document.createElementNS('http://www.w3.org/2000/svg', 'use');
  use.setAttribute('href', href);
  svg.appendChild(use);
  return svg;
}

function iconButton(href, label, onClick) {
  const button = document.createElement('button');
  button.type = 'button';
  button.className = 'icon-btn';
  button.setAttribute('aria-label', label);
  button.appendChild(svgIcon(href));
  button.addEventListener('click', (event) => {
    event.stopPropagation();
    onClick();
  });
  return button;
}

function chip(className, text) {
  const span = document.createElement('span');
  span.className = className;
  span.textContent = text;
  return span;
}

function meta(href, text) {
  const span = document.createElement('span');
  span.className = 'meta';
  span.appendChild(svgIcon(href));
  span.appendChild(document.createTextNode(text));
  return span;
}

function avatar(name) {
  const span = document.createElement('span');
  span.className = 'avatar';
  span.dataset.tint = String((hash(name) % 6) + 1);
  span.title = name;
  span.textContent = initials(name);
  return span;
}

function initials(name) {
  return name
    .split(/\s+/)
    .filter(Boolean)
    .slice(0, 2)
    .map((part) => part[0].toUpperCase())
    .join('');
}

function hash(value) {
  let total = 0;
  for (let i = 0; i < value.length; i += 1) {
    total = (total * 31 + value.charCodeAt(i)) % 997;
  }
  return total;
}

function formatDate(value) {
  if (!value) return 'No due date';
  const date = new Date(`${value}T00:00:00`);
  if (Number.isNaN(date.getTime())) return value;
  const day = String(date.getDate()).padStart(2, '0');
  const month = date.toLocaleString('en-GB', { month: 'short' });
  return `${day} ${month} ${date.getFullYear()}`;
}

/* ---------- drag and drop ---------- */

function wireDropzone(zone) {
  zone.addEventListener('dragover', (event) => {
    event.preventDefault();
    event.dataTransfer.dropEffect = 'move';
    zone.classList.add('is-over');
  });

  zone.addEventListener('dragleave', (event) => {
    if (!zone.contains(event.relatedTarget)) zone.classList.remove('is-over');
  });

  zone.addEventListener('drop', (event) => {
    event.preventDefault();
    zone.classList.remove('is-over');

    const taskId = event.dataTransfer.getData('text/plain') || state.draggingId;
    const task = state.tasks.find((item) => item.id === taskId);
    if (!task) return;

    const status = zone.dataset.dropzone;
    const before = cardBelow(zone, event.clientY);
    const changedStatus = task.status !== status;

    task.status = status;
    task.completed = status === 'done';
    if (status === 'done') task.stage = 'complete';

    moveInState(task, before ? before.dataset.id : null);
    render();

    const requests = [persistOrder()];
    if (changedStatus) {
      requests.push(
        saveTask(task.id, { status, stage: task.stage }).catch((error) => {
          console.error(error);
          fetchTasks();
        })
      );
    }
    Promise.all(requests);
  });
}

function cardBelow(zone, y) {
  const cards = [...zone.querySelectorAll('.card:not(.is-dragging)')];
  return cards.find((card) => {
    const box = card.getBoundingClientRect();
    return y < box.top + box.height / 2;
  });
}

function moveInState(task, beforeId) {
  const rest = state.tasks.filter((item) => item.id !== task.id);
  const index = beforeId ? rest.findIndex((item) => item.id === beforeId) : -1;
  if (index === -1) {
    rest.push(task);
  } else {
    rest.splice(index, 0, task);
  }
  state.tasks = rest;
}

/* ---------- modal ---------- */

function openModal(task = null, status = 'todo') {
  state.editingId = task ? task.id : null;
  el.modalTitle.textContent = task ? 'Edit task' : 'New task';
  el.modalSubmit.textContent = task ? 'Save changes' : 'Create task';

  el.form.elements.title.value = task ? task.title : '';
  el.form.elements.description.value = task ? task.description : '';
  el.form.elements.status.value = task ? task.status : status;
  el.form.elements.stage.value = task ? task.stage : 'not_started';
  el.form.elements.priority.value = task ? task.priority : 'medium';
  el.form.elements.due_date.value = task ? task.due_date : '';
  el.form.elements.assignees.value = task ? (task.assignees || []).join(', ') : '';
  el.form.elements.subtasks_done.value = task ? task.subtasks_done : 0;
  el.form.elements.subtasks_total.value = task ? task.subtasks_total : 0;

  el.overlay.hidden = false;
  el.form.elements.title.focus();
}

function closeModal() {
  el.overlay.hidden = true;
  state.editingId = null;
  el.form.reset();
}

function submitTask(event) {
  event.preventDefault();

  const payload = {
    title: el.form.elements.title.value.trim(),
    description: el.form.elements.description.value.trim(),
    status: el.form.elements.status.value,
    stage: el.form.elements.stage.value,
    priority: el.form.elements.priority.value,
    due_date: el.form.elements.due_date.value,
    assignees: el.form.elements.assignees.value
      .split(',')
      .map((name) => name.trim())
      .filter(Boolean),
    subtasks_done: Number(el.form.elements.subtasks_done.value) || 0,
    subtasks_total: Number(el.form.elements.subtasks_total.value) || 0,
  };

  if (!payload.title) return;

  saveTask(state.editingId, payload)
    .then(() => {
      closeModal();
      fetchTasks();
    })
    .catch((error) => console.error(error));
}
