// API base URL - configured in index.html
const API_URL = window.API_BASE_URL;

// DOM elements
const tasksTable = document.getElementById('tasksTable');
const tasksBody = document.getElementById('tasksBody');
const createBtn = document.getElementById('createBtn');
const taskModal = document.getElementById('taskModal');
const modalTitle = document.getElementById('modalTitle');
const taskForm = document.getElementById('taskForm');
const closeBtn = document.querySelector('.close');

// Current task being edited
let currentTaskId = null;

// Load tasks on page load
document.addEventListener('DOMContentLoaded', loadTasks);

// Event listeners
createBtn.addEventListener('click', () => showModal());
closeBtn.addEventListener('click', hideModal);
taskForm.addEventListener('submit', handleFormSubmit);

// Close modal when clicking outside
window.addEventListener('click', (e) => {
    if (e.target === taskModal) {
        hideModal();
    }
});

// Load all tasks from API
async function loadTasks() {
    try {
        const response = await fetch(`${API_URL}/tasks`);
        if (!response.ok) throw new Error('Failed to load tasks');
        const tasks = await response.json();
        renderTasks(tasks);
    } catch (error) {
        console.error('Error loading tasks:', error);
        alert('Failed to load tasks. Please check the console for details.');
    }
}

// Render tasks in the table
function renderTasks(tasks) {
    tasksBody.innerHTML = '';
    tasks.forEach(task => {
        const row = document.createElement('tr');

        const priorityClass = `priority-${task.priority}`;
        const priorityBadge = `<span class="priority-badge ${priorityClass}">${task.priority}</span>`;

        row.innerHTML = `
            <td>${task.id}</td>
            <td>${task.title}</td>
            <td>${task.description || ''}</td>
            <td>${task.status.replace('_', ' ')}</td>
            <td>${priorityBadge}</td>
            <td>${task.assigned_to || ''}</td>
            <td>${task.estimated_hours || ''}</td>
            <td>${task.tags || ''}</td>
            <td>
                <button class="btn btn-warning" onclick="editTask(${task.id})">Edit</button>
                <button class="btn btn-danger" onclick="deleteTask(${task.id})">Delete</button>
            </td>
        `;

        tasksBody.appendChild(row);
    });
}

// Show modal for create or edit
function showModal(task = null) {
    if (task) {
        modalTitle.textContent = 'Edit Task';
        currentTaskId = task.id;
        // Populate form
        document.getElementById('title').value = task.title;
        document.getElementById('description').value = task.description || '';
        document.getElementById('status').value = task.status;
        document.getElementById('priority').value = task.priority;
        document.getElementById('assigned_to').value = task.assigned_to || '';
        document.getElementById('estimated_hours').value = task.estimated_hours || '';
        document.getElementById('tags').value = task.tags || '';
    } else {
        modalTitle.textContent = 'Create Task';
        currentTaskId = null;
        taskForm.reset();
    }
    taskModal.style.display = 'block';
}

// Hide modal
function hideModal() {
    taskModal.style.display = 'none';
    currentTaskId = null;
    taskForm.reset();
}

// Handle form submission
async function handleFormSubmit(event) {
    event.preventDefault();

    const formData = new FormData(taskForm);
    const data = {
        title: formData.get('title'),
        description: formData.get('description'),
        status: formData.get('status'),
        priority: formData.get('priority'),
        assigned_to: formData.get('assigned_to'),
        estimated_hours: formData.get('estimated_hours') ? parseFloat(formData.get('estimated_hours')) : null,
        tags: formData.get('tags')
    };

    try {
        let response;
        if (currentTaskId) {
            // Update
            response = await fetch(`${API_URL}/tasks/${currentTaskId}`, {
                method: 'PUT',
                headers: { 'Content-Type': 'application/json' },
                body: JSON.stringify(data)
            });
        } else {
            // Create
            response = await fetch(`${API_URL}/tasks`, {
                method: 'POST',
                headers: { 'Content-Type': 'application/json' },
                body: JSON.stringify(data)
            });
        }

        if (!response.ok) {
            const error = await response.json();
            throw new Error(error.error || 'Failed to save task');
        }

        hideModal();
        loadTasks(); // Reload tasks
    } catch (error) {
        console.error('Error saving task:', error);
        alert(`Failed to save task: ${error.message}`);
    }
}

// Edit task
async function editTask(id) {
    try {
        const response = await fetch(`${API_URL}/tasks/${id}`);
        if (!response.ok) throw new Error('Failed to load task');
        const task = await response.json();
        showModal(task);
    } catch (error) {
        console.error('Error loading task for edit:', error);
        alert('Failed to load task for editing.');
    }
}

// Delete task
async function deleteTask(id) {
    if (!confirm('Are you sure you want to delete this task?')) return;

    try {
        const response = await fetch(`${API_URL}/tasks/${id}`, {
            method: 'DELETE'
        });

        if (!response.ok) throw new Error('Failed to delete task');

        loadTasks(); // Reload tasks
    } catch (error) {
        console.error('Error deleting task:', error);
        alert('Failed to delete task.');
    }
}