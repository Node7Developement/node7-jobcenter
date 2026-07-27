'use strict';

const resourceName = typeof GetParentResourceName === 'function' ? GetParentResourceName() : 'node7-jobcenter';
const app = document.getElementById('app');
const body = document.body;
const categories = document.getElementById('categories');
const jobList = document.getElementById('jobList');
const emptyJobs = document.getElementById('emptyJobs');
const emptyDetails = document.getElementById('emptyDetails');
const jobDetails = document.getElementById('jobDetails');
const restrictedNotice = document.getElementById('restrictedNotice');
const leaveButton = document.getElementById('leaveButton');
const primaryButton = document.getElementById('primaryButton');
const routeButton = document.getElementById('routeButton');
const currentHint = document.getElementById('currentHint');

const state = {
    visible: false,
    jobs: [],
    categories: [],
    currentJob: { name: 'unemployed', label: 'Civilian', grade: 'Freelancer' },
    selected: null,
    category: 'all',
    loading: false,
    error: ''
};


function setShellVisible(visible) {
    body.classList.toggle('nui-hidden', !visible);
    app.classList.toggle('is-hidden', !visible);
    app.setAttribute('aria-hidden', visible ? 'false' : 'true');
    app.style.visibility = visible ? 'visible' : 'hidden';
    app.style.opacity = visible ? '1' : '0';
    app.style.pointerEvents = visible ? 'auto' : 'none';
}

function post(endpoint, data = {}) {
    return fetch(`https://${resourceName}/${endpoint}`, {
        method: 'POST',
        headers: { 'Content-Type': 'application/json; charset=UTF-8' },
        body: JSON.stringify(data)
    }).then((response) => response.json()).catch(() => ({ ok: false }));
}

function setText(id, value) {
    const element = document.getElementById(id);
    if (element) element.textContent = value == null ? '' : String(value);
}

function clear(element) {
    while (element.firstChild) element.removeChild(element.firstChild);
}

function closeBoard() {
    if (!state.visible) return;
    state.visible = false;
    state.selected = null;
    setShellVisible(false);
    post('close');
}

function categoryName(id) {
    const match = state.categories.find((category) => category.id === id);
    return match ? match.label : id;
}

function visibleJobs() {
    return state.category === 'all'
        ? state.jobs
        : state.jobs.filter((job) => job.category === state.category);
}

function renderCategories() {
    clear(categories);
    state.categories.forEach((category) => {
        const button = document.createElement('button');
        button.type = 'button';
        button.className = `category-tab${state.category === category.id ? ' is-active' : ''}`;
        button.textContent = category.label;
        button.addEventListener('click', () => {
            state.category = category.id;
            state.selected = null;
            renderCategories();
            renderJobs();
            renderDetails();
        });
        categories.appendChild(button);
    });
}

function renderJobs() {
    clear(jobList);
    const jobs = visibleJobs();
    emptyJobs.classList.toggle('is-hidden', jobs.length !== 0);

    const emptyTitle = emptyJobs.querySelector('strong');
    const emptyCopy = emptyJobs.querySelector('p');
    if (emptyTitle && emptyCopy) {
        if (state.loading) {
            emptyTitle.textContent = 'CHECKING PUBLIC WORK';
            emptyCopy.textContent = 'Reviewing the work notices currently available in this territory.';
        } else if (state.error) {
            emptyTitle.textContent = 'RECORDS UNAVAILABLE';
            emptyCopy.textContent = state.error;
        } else {
            emptyTitle.textContent = 'NO PUBLIC WORK POSTED';
            emptyCopy.textContent = 'No public jobs are configured. Check Config.PublicJobs and the server console.';
        }
    }

    jobs.forEach((job, index) => {
        const notice = document.createElement('button');
        notice.type = 'button';
        notice.className = `job-notice${state.selected && state.selected.name === job.name ? ' is-selected' : ''}`;
        notice.style.setProperty('--tilt', `${index % 2 === 0 ? -0.35 : 0.35}deg`);

        const badge = document.createElement('span');
        badge.className = 'notice-badge';
        badge.textContent = job.badge;

        const copy = document.createElement('span');
        copy.className = 'notice-copy';
        const type = document.createElement('small');
        type.textContent = categoryName(job.category).toUpperCase();
        const title = document.createElement('strong');
        title.textContent = job.label;
        const location = document.createElement('span');
        location.textContent = job.location;
        copy.append(type, title, location);

        const status = document.createElement('em');
        status.textContent = state.currentJob.name === job.name ? 'CURRENT JOB' : (job.available === false ? 'CORE JOB MISSING' : 'AVAILABLE');

        notice.append(badge, copy, status);
        notice.addEventListener('click', () => {
            state.selected = job;
            renderJobs();
            renderDetails();
        });
        jobList.appendChild(notice);
    });
}

function renderDetails() {
    const job = state.selected;
    if (!job) {
        emptyDetails.classList.remove('is-hidden');
        jobDetails.classList.add('is-hidden');
        return;
    }

    emptyDetails.classList.add('is-hidden');
    jobDetails.classList.remove('is-hidden');
    setText('detailBadge', job.badge);
    setText('detailCategory', categoryName(job.category).toUpperCase());
    setText('detailTitle', job.label);
    setText('detailLocation', job.location);
    setText('detailDescription', job.description);
    setText('detailGrade', job.startingGrade || 'Worker');
    setText('detailStart', job.startLabel || job.location || 'Work Site');

    const current = state.currentJob.name === job.name;
    const protectedJob = Boolean(state.currentJob.protected);
    const unavailable = job.available === false;
    currentHint.classList.toggle('is-hidden', !current);
    primaryButton.disabled = protectedJob || unavailable;
    primaryButton.textContent = protectedJob
        ? 'Department Job Active'
        : (unavailable ? 'Core Job Missing' : (current ? 'Go to Work' : 'Take Job'));
    routeButton.disabled = !job.workCoords;
    const status = document.querySelector('.work-facts .available');
    if (status) {
        status.textContent = unavailable ? 'DEFINITION MISSING' : 'WORK AVAILABLE';
        status.classList.toggle('is-missing', unavailable);
    }
}

function openBoard(payload) {
    state.visible = true;
    state.jobs = Array.isArray(payload.jobs) ? payload.jobs : [];
    state.categories = Array.isArray(payload.categories) ? payload.categories : [{ id: 'all', label: 'All Work' }];
    state.currentJob = payload.currentJob || state.currentJob;
    state.selected = null;
    state.category = 'all';
    state.loading = payload.loading === true;
    state.error = '';

    setText('title', payload.brand && payload.brand.title ? payload.brand.title : 'NODE7 EMPLOYMENT BOARD');
    setText('subtitle', payload.brand && payload.brand.subtitle ? payload.brand.subtitle : 'PUBLIC WORK • NO WHITELIST');
    setText('centerLabel', payload.centerLabel || 'Public Employment Office');
    setText('currentJobLabel', state.currentJob.label || 'Civilian');
    setText('currentJobGrade', state.currentJob.grade || 'Freelancer');

    restrictedNotice.classList.toggle('is-hidden', !state.currentJob.protected);
    leaveButton.classList.toggle('is-hidden', !state.currentJob.isPublic);

    renderCategories();
    renderJobs();
    renderDetails();

    setShellVisible(true);
}

window.addEventListener('message', (event) => {
    const message = event.data || {};
    if (message.action === 'open') openBoard(message.payload || {});
    if (message.action === 'boardError') {
        state.loading = false;
        state.error = String(message.message || 'Employment records could not be loaded.');
        renderJobs();
        renderDetails();
        setShellVisible(true);
    }
    if (message.action === 'close') {
        state.visible = false;
        setShellVisible(false);
    }
});

document.getElementById('closeButton').addEventListener('click', closeBoard);

leaveButton.addEventListener('click', () => {
    if (!leaveButton.classList.contains('is-hidden')) post('leaveJob');
});

routeButton.addEventListener('click', () => {
    if (!state.selected || routeButton.disabled) return;
    post('markWork', { jobName: state.selected.name });
});

primaryButton.addEventListener('click', () => {
    if (!state.selected || primaryButton.disabled) return;
    const current = state.currentJob.name === state.selected.name;
    post(current ? 'goToWork' : 'takeJob', { jobName: state.selected.name });
});

window.addEventListener('keydown', (event) => {
    if (state.visible && event.key === 'Escape') closeBoard();
});

setShellVisible(false);
