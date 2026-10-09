/* Gia phả: cùng cấu trúc familyPeople với bản Flutter, lưu riêng trên thiết bị. */
let familyBranchFilter = 'all';
let familyView = 'tree';

function familyById(id) {
  return appFamily.find(person => person.id === id);
}

function familyEscape(value) {
  return String(value ?? '').replace(/[&<>"']/g, char => ({
    '&': '&amp;', '<': '&lt;', '>': '&gt;', '"': '&quot;', "'": '&#39;'
  })[char]);
}

function familyBranchLabel(branch) {
  return branch === 'noi' ? 'Bên nội' : branch === 'ngoai' ? 'Bên ngoại' : 'Nhánh khác';
}

function familyYear(date) {
  return Number(String(date || '').split('/').pop()) || 9999;
}

function familyCard(person, generation) {
  const life = [person.birthDate ? `Sinh ${person.birthDate}` : '', person.deathDate ? `Mất ${person.deathDate}` : ''].filter(Boolean).join(' · ');
  const subtitle = [generation ? `Đời ${generation}` : familyBranchLabel(person.branch), life].filter(Boolean).join(' · ');
  const icon = person.gender === 'female' ? 'fa-person-dress' : 'fa-user';
  return `<button type="button" class="family-person-card" data-family-open="${familyEscape(person.id)}" aria-label="Xem hồ sơ ${familyEscape(person.name)}">
    <span class="family-person-avatar"><i class="fa-solid ${icon}"></i></span>
    <span class="family-person-info"><strong>${familyEscape(person.name)}</strong><small>${familyEscape(subtitle || 'Chưa rõ ngày sinh')}</small></span>
    <i class="fa-solid fa-chevron-right" aria-hidden="true"></i>
  </button>`;
}

function setFamilyBranch(branch) {
  familyBranchFilter = branch;
  renderFamily();
}

function setFamilyView(view) {
  familyView = view;
  renderFamily();
}

function renderFamily() {
  const content = document.getElementById('familyContent');
  if (!content) return;
  const people = Array.isArray(appFamily) ? appFamily.filter(p => p && p.id && p.name) : [];
  const search = document.getElementById('familySearch').value.trim().toLocaleLowerCase('vi');
  const filtered = people.filter(person =>
    (familyBranchFilter === 'all' || person.branch === familyBranchFilter) &&
    (!search || [person.name, person.hometown, person.notes].some(value => String(value || '').toLocaleLowerCase('vi').includes(search)))
  ).sort((a, b) => familyYear(a.birthDate) - familyYear(b.birthDate) || a.name.localeCompare(b.name, 'vi'));

  document.getElementById('sidebarFamilyCount').textContent = people.length;
  document.getElementById('familyStats').innerHTML =
    `<span>${people.length} thành viên</span><span>${people.filter(p => p.branch === 'noi').length} bên nội</span><span>${people.filter(p => p.branch === 'ngoai').length} bên ngoại</span>`;
  document.getElementById('familyResultCount').textContent = `${filtered.length} người ${familyBranchFilter === 'all' ? 'trong gia phả' : 'thuộc ' + familyBranchLabel(familyBranchFilter).toLowerCase()}`;
  document.querySelectorAll('[data-family-branch]').forEach(button => button.classList.toggle('active', button.dataset.familyBranch === familyBranchFilter));
  document.getElementById('familyTreeButton').classList.toggle('active', familyView === 'tree');
  document.getElementById('familyListButton').classList.toggle('active', familyView === 'list');

  if (!people.length) {
    content.innerHTML = `<div class="family-empty"><i class="fa-solid fa-people-roof"></i><h3>Gia phả chưa có ai</h3>
      <p>Bắt đầu từ bản thân hoặc một người lớn tuổi, rồi nối cha mẹ và con cháu.</p>
      <button class="btn-royal" onclick="openFamilyForm()"><i class="fa-solid fa-user-plus"></i> Thêm người đầu tiên</button></div>`;
    return;
  }
  if (!filtered.length) {
    content.innerHTML = `<div class="family-empty"><i class="fa-solid fa-magnifying-glass"></i><h3>Không tìm thấy người phù hợp</h3><p>Thử đổi nhánh hoặc từ khóa tìm kiếm.</p></div>`;
    return;
  }
  if (familyView === 'list' || search) {
    content.innerHTML = `<div class="family-list">${filtered.map(person => familyCard(person, 0)).join('')}</div>`;
    return;
  }

  const ids = new Set(filtered.map(p => p.id));
  const parentFor = person => ids.has(person.fatherId) ? person.fatherId : ids.has(person.motherId) ? person.motherId : '';
  const roots = filtered.filter(person => !parentFor(person));
  const renderNode = (person, generation, path) => {
    if (path.has(person.id) || generation > filtered.length) return '';
    const nextPath = new Set([...path, person.id]);
    const children = filtered.filter(child => child.id !== person.id && parentFor(child) === person.id);
    return `<div class="family-tree-node">${familyCard(person, generation)}
      ${children.length ? `<div class="family-tree-children">${children.map(child => renderNode(child, generation + 1, nextPath)).join('')}</div>` : ''}</div>`;
  };
  content.innerHTML = roots.length
    ? `<div class="family-tree">${roots.map(person => renderNode(person, 1, new Set())).join('')}</div>`
    : `<div class="family-list">${filtered.map(person => familyCard(person, 0)).join('')}</div>`;
}

function saveFamily() {
  try {
    localStorage.setItem(STORAGE_KEY_FAMILY, JSON.stringify(appFamily));
    renderFamily();
    return true;
  } catch (error) {
    alert('Không thể lưu gia phả trên thiết bị này. Hãy kiểm tra dung lượng bộ nhớ trình duyệt.');
    return false;
  }
}

function familySelectOptions(selectedId, ownId) {
  const others = appFamily.filter(p => p.id !== ownId).sort((a, b) => a.name.localeCompare(b.name, 'vi'));
  return `<option value="">Chưa rõ</option>${others.map(p =>
    `<option value="${familyEscape(p.id)}" ${p.id === selectedId ? 'selected' : ''}>${familyEscape(p.name)} · ${familyBranchLabel(p.branch)}</option>`
  ).join('')}`;
}

function openFamilyForm(id = '') {
  const person = id ? familyById(id) : null;
  document.getElementById('familyFormTitle').textContent = person ? 'Sửa hồ sơ người thân' : 'Thêm người thân';
  document.getElementById('familyId').value = person?.id || '';
  const fields = {
    familyName: person?.name || '', familyGender: person?.gender || 'other',
    familyBranch: person?.branch || (familyBranchFilter === 'all' ? 'noi' : familyBranchFilter),
    familyBirthDate: person?.birthDate || '', familyDeathDate: person?.deathDate || '',
    familyBirthCalendar: person?.birthCalendar || 'solar', familyDeathCalendar: person?.deathCalendar || 'solar',
    familyHometown: person?.hometown || '', familyRestingPlace: person?.restingPlace || '',
    familyNotes: person?.notes || ''
  };
  for (const [field, value] of Object.entries(fields)) document.getElementById(field).value = value;
  document.getElementById('familyFather').innerHTML = familySelectOptions(person?.fatherId || '', id);
  document.getElementById('familyMother').innerHTML = familySelectOptions(person?.motherId || '', id);
  const spouses = document.getElementById('familySpouses');
  spouses.replaceChildren();
  for (const other of appFamily.filter(p => p.id !== id).sort((a, b) => a.name.localeCompare(b.name, 'vi'))) {
    const label = document.createElement('label');
    const checkbox = document.createElement('input');
    checkbox.type = 'checkbox';
    checkbox.value = other.id;
    checkbox.checked = (person?.spouseIds || []).includes(other.id);
    label.append(checkbox, document.createTextNode(`${other.name} · ${familyBranchLabel(other.branch)}`));
    spouses.append(label);
  }
  if (!spouses.children.length) spouses.textContent = 'Thêm người thân khác để nối quan hệ.';
  document.getElementById('familyFormError').textContent = '';
  openModal('familyFormModal');
  setTimeout(() => document.getElementById('familyName').focus(), 50);
}

function familyValidDate(value, calendar) {
  if (!value) return true;
  if (/^\d{1,4}$/.test(value)) return Number(value) > 0;
  const match = /^(\d{1,2})\/(\d{1,2})\/(\d{1,4})$/.exec(value);
  if (!match) return false;
  const day = Number(match[1]), month = Number(match[2]), year = Number(match[3]);
  if (year < 1 || month < 1 || month > 12 || day < 1) return false;
  if (calendar === 'lunar') return day <= 30;
  const leap = year % 4 === 0 && (year % 100 !== 0 || year % 400 === 0);
  const max = [31, leap ? 29 : 28, 31, 30, 31, 30, 31, 31, 30, 31, 30, 31][month - 1];
  return day <= max;
}

function familyCycle(personId, candidateParentId) {
  if (!candidateParentId) return false;
  const descendants = new Map();
  for (const person of appFamily) {
    for (const parentId of [person.fatherId, person.motherId]) {
      if (parentId) descendants.set(parentId, [...(descendants.get(parentId) || []), person.id]);
    }
  }
  const pending = [personId], seen = new Set();
  while (pending.length) {
    const id = pending.pop();
    if (id === candidateParentId) return true;
    if (seen.has(id)) continue;
    seen.add(id);
    pending.push(...(descendants.get(id) || []));
  }
  return false;
}

function saveFamilyPerson() {
  const field = id => document.getElementById(id).value.trim();
  const error = document.getElementById('familyFormError');
  error.textContent = '';
  const name = field('familyName');
  const birthDate = field('familyBirthDate'), deathDate = field('familyDeathDate');
  const fatherId = field('familyFather'), motherId = field('familyMother');
  const spouseIds = [...document.querySelectorAll('#familySpouses input:checked')].map(box => box.value);
  const id = field('familyId') || `person_${Date.now()}_${Math.random().toString(36).slice(2, 8)}`;
  if (!name) { error.textContent = 'Vui lòng nhập họ và tên.'; return; }
  if (!familyValidDate(birthDate, field('familyBirthCalendar')) || !familyValidDate(deathDate, field('familyDeathCalendar'))) {
    error.textContent = 'Ngày tháng cần nhập theo năm hoặc ngày/tháng/năm hợp lệ.'; return;
  }
  if (fatherId && fatherId === motherId) { error.textContent = 'Cha và mẹ phải là hai người khác nhau.'; return; }
  if (familyCycle(id, fatherId) || familyCycle(id, motherId)) {
    error.textContent = 'Không thể chọn con hoặc cháu làm cha mẹ.'; return;
  }
  if (spouseIds.includes(fatherId) || spouseIds.includes(motherId)) {
    error.textContent = 'Cha hoặc mẹ không thể đồng thời là vợ/chồng.'; return;
  }
  const person = {
    id, name, gender: field('familyGender'), branch: field('familyBranch'),
    birthDate, deathDate, birthCalendar: field('familyBirthCalendar'), deathCalendar: field('familyDeathCalendar'),
    fatherId, motherId, spouseIds, hometown: field('familyHometown'),
    restingPlace: field('familyRestingPlace'), notes: field('familyNotes')
  };
  const previous = appFamily;
  appFamily = [...appFamily.filter(p => p.id !== id), person].map(p => {
    if (p.id === id) return p;
    const links = (p.spouseIds || []).filter(otherId => otherId !== id);
    if (spouseIds.includes(p.id)) links.push(id);
    return { ...p, spouseIds: links };
  });
  if (!saveFamily()) { appFamily = previous; return; }
  closeModal('familyFormModal');
}

function familyRelativeGroup(label, people) {
  const buttons = people.filter(Boolean).map(person =>
    `<button type="button" data-family-open="${familyEscape(person.id)}"><i class="fa-regular fa-user"></i> ${familyEscape(person.name)}</button>`).join('');
  return `<h5>${label}</h5>${buttons || '<span class="family-unknown">Chưa ghi nhận</span>'}`;
}

function showFamilyDetail(id) {
  const person = familyById(id);
  if (!person) return;
  const children = appFamily.filter(p => p.fatherId === id || p.motherId === id);
  const siblings = appFamily.filter(p => p.id !== id &&
    ((person.fatherId && p.fatherId === person.fatherId) || (person.motherId && p.motherId === person.motherId)));
  const parents = [person.fatherId, person.motherId].map(familyById).filter(Boolean);
  const grandparentIds = new Set(parents.flatMap(p => [p.fatherId, p.motherId]).filter(Boolean));
  const grandparents = [...grandparentIds].map(familyById).filter(Boolean);
  const parentIds = new Set(parents.map(p => p.id));
  const extended = appFamily.filter(p => !parentIds.has(p.id) &&
    ((p.fatherId && grandparentIds.has(p.fatherId)) || (p.motherId && grandparentIds.has(p.motherId))));
  const extendedIds = new Set(extended.map(p => p.id));
  const cousins = appFamily.filter(p => extendedIds.has(p.fatherId) || extendedIds.has(p.motherId));
  const dateText = (value, calendar) => value ? `${familyEscape(value)} (${calendar === 'lunar' ? 'âm lịch' : 'dương lịch'})` : 'Chưa rõ';
  const field = (label, value) => `<div class="family-detail-field"><small>${label}</small><strong>${value || '—'}</strong></div>`;
  const icon = person.gender === 'female' ? 'fa-person-dress' : 'fa-user';
  document.getElementById('familyDetailTitle').textContent = 'Hồ sơ người thân';
  document.getElementById('familyDetailBody').innerHTML = `
    <div class="family-detail-name"><span class="family-person-avatar"><i class="fa-solid ${icon}"></i></span>
      <div><h4>${familyEscape(person.name)}</h4><p>${familyBranchLabel(person.branch)}</p></div></div>
    <div class="family-detail-grid">
      ${field('Ngày sinh', dateText(person.birthDate, person.birthCalendar))}
      ${field('Ngày mất', person.deathDate ? dateText(person.deathDate, person.deathCalendar) : '—')}
      ${field('Quê quán', familyEscape(person.hometown))}
      ${field('Nơi an nghỉ', familyEscape(person.restingPlace))}
    </div>
    <div class="family-relatives">
      ${familyRelativeGroup('Cha', [familyById(person.fatherId)])}
      ${familyRelativeGroup('Mẹ', [familyById(person.motherId)])}
      ${familyRelativeGroup('Vợ / chồng', (person.spouseIds || []).map(familyById))}
      ${familyRelativeGroup('Con', children)}
      ${familyRelativeGroup('Anh chị em', siblings)}
      ${grandparents.length ? familyRelativeGroup('Ông bà', grandparents) : ''}
      ${extended.length ? familyRelativeGroup('Anh chị em của cha mẹ', extended) : ''}
      ${cousins.length ? familyRelativeGroup('Anh chị em họ', cousins) : ''}
    </div>
    ${person.notes ? `<div class="family-relatives"><h5>Ghi chép</h5><p style="white-space:pre-wrap;line-height:1.6;font-size:13px">${familyEscape(person.notes)}</p></div>` : ''}`;
  document.getElementById('familyEditButton').onclick = () => { closeModal('familyDetailModal'); openFamilyForm(id); };
  document.getElementById('familyDeleteButton').onclick = () => deleteFamilyPerson(id);
  openModal('familyDetailModal');
}

function deleteFamilyPerson(id) {
  const person = familyById(id);
  if (!person || !confirm(`Xóa ${person.name}? Các liên kết đến người này sẽ được gỡ; hồ sơ người thân khác vẫn được giữ.`)) return;
  const previous = appFamily;
  appFamily = appFamily.filter(p => p.id !== id).map(p => ({
    ...p,
    fatherId: p.fatherId === id ? '' : p.fatherId,
    motherId: p.motherId === id ? '' : p.motherId,
    spouseIds: (p.spouseIds || []).filter(spouseId => spouseId !== id)
  }));
  if (!saveFamily()) { appFamily = previous; return; }
  closeModal('familyDetailModal');
}

function handleMobileAdd() {
  if (document.getElementById('tab-family').style.display !== 'none') openFamilyForm();
  else openAddEventModal();
}

document.addEventListener('click', event => {
  const button = event.target.closest('[data-family-open]');
  if (button) showFamilyDetail(button.dataset.familyOpen);
});
