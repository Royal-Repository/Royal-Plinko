// --- CONFIGURATION ---
const rows = 16;
const ROW_HEIGHT = 34;
const PEG_GAP = 17;
const BALL_SIZE = 11;

// Elements
const board = document.getElementById('board');
const multiRow = document.getElementById('multiplier-row');
const playBtn = document.getElementById('play-btn');
const balanceEl = document.getElementById('balance-display');
const container = document.getElementById('ui-container');
const stage = document.querySelector('.plinko-stage');

const multipliersConfig = {
    low: [16, 9, 2, 1.4, 1.4, 1.2, 1.1, 1, 0.5, 1, 1.1, 1.2, 1.4, 1.4, 2, 9, 16],
    medium: [110, 41, 10, 5, 3, 1.5, 1, 0.5, 0.3, 0.5, 1, 1.5, 3, 5, 10, 41, 110],
    high: [1000, 130, 26, 9, 4, 2, 0.2, 0.2, 0.2, 0.2, 0.2, 2, 4, 9, 26, 130, 1000]
};

// --- INITIALIZATION ---
function initBoard() {
    board.innerHTML = '';
    for (let i = 0; i < rows; i++) {
        const rowDiv = document.createElement('div');
        rowDiv.className = 'peg-row';
        for (let j = 0; j < 3 + i; j++) {
            const peg = document.createElement('div');
            peg.className = 'peg';
            rowDiv.appendChild(peg);
        }
        board.appendChild(rowDiv);
    }
    updateMultipliers();
}

function getColorForMult(val) {
    if (val < 1) return '#ff4949';
    if (val < 2) return '#ffb830';
    return '#44c978';
}

function updateMultipliers() {
    const risk = document.getElementById('risk-level').value;
    const vals = multipliersConfig[risk];
    if (!vals) return;
    multiRow.innerHTML = '';
    vals.forEach((m, index) => {
        const div = document.createElement('div');
        div.className = 'mult-box';
        div.textContent = m + 'x';
        div.style.background = getColorForMult(m);
        div.id = `slot-${index + 1}`;
        multiRow.appendChild(div);
    });
}

document.getElementById('risk-level').addEventListener('change', updateMultipliers);

// Helpers
function getBalance() { return parseFloat(balanceEl.innerText.replace('$', '')) || 0; }
function setBalance(amount) { balanceEl.innerText = '$' + Math.floor(amount); }

// --- PLAY LOGIC ---
playBtn.addEventListener('click', () => {
    const bet = parseFloat(document.getElementById('bet-amount').value);
    const balls = parseInt(document.getElementById('ball-count').value);
    const risk = document.getElementById('risk-level').value;

    if (isNaN(bet) || bet <= 0) return;
    if (isNaN(balls) || balls < 1 || balls > 20) return;

    playBtn.disabled = true;

    fetch(`https://${GetParentResourceName()}/play`, {
        method: 'POST',
        body: JSON.stringify({ bet: bet, risk: risk, balls: balls })
    }).then(resp => resp.json()).then(resp => {
        if (resp.status) {
            // Deduct total bet visually
            setBalance(resp.newBalance);
            // Start Animation
            spawnBalls(resp.results);
        } else {
            playBtn.disabled = false;
        }
    }).catch(e => {
        console.error(e);
        playBtn.disabled = false;
    });
});

function spawnBalls(results) {
    let completedBalls = 0;
    const totalBalls = results.length;

    results.forEach((res, index) => {
        // Stagger drops (Rain effect)
        setTimeout(() => {
            createBall(res.slot, res.multiplier, () => {

                // 1. Update UI Balance Visually
                if (res.win > 0) {
                    setBalance(getBalance() + res.win);
                }

                // 2. Check for completion
                completedBalls++;
                if (completedBalls >= totalBalls) {
                    playBtn.disabled = false;
                    // 3. Trigger Server Payout (Actual Inventory Item)
                    fetch(`https://${GetParentResourceName()}/gameover`, { method: 'POST' });
                }
            });
        }, index * 150);
    });
}

// --- PHYSICS ENGINE ---
// --- PHYSICS ENGINE ---
function createBall(targetSlot, multiplier, onFinish) {
    const ball = document.createElement('div');
    ball.className = 'ball';
    ball.style.width = `${BALL_SIZE}px`;
    ball.style.height = `${BALL_SIZE}px`;
    stage.appendChild(ball);

    const totalSteps = rows;
    const rightsNeeded = targetSlot - 1;
    let moves = [];
    for (let i = 0; i < rightsNeeded; i++) moves.push(1);
    while (moves.length < totalSteps) moves.push(-1);
    moves.sort(() => Math.random() - 0.5);

    const startTime = performance.now();
    // Faster speed: 200ms per row (was 280)
    const durationPerStep = 200;
    const totalDuration = totalSteps * durationPerStep;

    // Add random horizontal jitter for realism
    const jitterMap = moves.map(() => (Math.random() - 0.5) * 4);

    ball.style.top = '0px';
    ball.style.left = '50%';

    function frame(time) {
        const elapsed = time - startTime;
        if (elapsed >= totalDuration) {
            finishBall(ball, targetSlot, onFinish);
            return;
        }

        const currentStepIdx = Math.floor(elapsed / durationPerStep);
        const stepProgress = (elapsed % durationPerStep) / durationPerStep;
        const direction = moves[currentStepIdx] || 0;

        const startY = currentStepIdx * ROW_HEIGHT;
        // Improved drop curve (Standard Gravity: 0.5 * g * t^2)
        // Adjust easing to be slightly less "stoppy"
        const dropY = ROW_HEIGHT * (stepProgress * stepProgress);
        const y = startY + dropY;

        let baseX = 0;
        for (let i = 0; i < currentStepIdx; i++) baseX += (moves[i] * PEG_GAP);

        // Smoother Transition using Sine ease-in-out for X
        // const driftX = (direction * PEG_GAP) * stepProgress; // Linear is boring
        // Use a slight S-curve for horizontal movement
        const easeX = stepProgress < 0.5 ? 2 * stepProgress * stepProgress : 1 - Math.pow(-2 * stepProgress + 2, 2) / 2;
        const driftX = (direction * PEG_GAP) * easeX;

        // Bounce effect when hitting pegs (at stepProgress ~ 0 or 1)
        // Max bounce at 50%? No, curve is deviation from center line.
        const bounceAmplitude = 4;
        const curve = Math.sin(stepProgress * Math.PI) * (direction * bounceAmplitude);

        // Add Jitter
        const currentJitter = jitterMap[currentStepIdx] || 0;
        const jitter = currentJitter * Math.sin(stepProgress * Math.PI); // Jitter peaks mid-air

        const x = baseX + driftX + curve + jitter;

        // Rotation Effect
        const rotation = elapsed * 0.8; // Spin based on time

        ball.style.transform = `translate(calc(-50% + ${x}px), ${y}px) rotate(${rotation}deg)`;
        requestAnimationFrame(frame);
    }
    requestAnimationFrame(frame);
}

function finishBall(ballEl, slotIdx, callback) {
    const winningBox = document.getElementById(`slot-${slotIdx}`);
    if (winningBox) {
        winningBox.classList.add('hit-anim');
        setTimeout(() => winningBox.classList.remove('hit-anim'), 200);
    }
    ballEl.remove();
    if (callback) callback();
}

window.adjustBet = function (factor) {
    const input = document.getElementById('bet-amount');
    let val = parseFloat(input.value) || 0;
    input.value = Math.max(1, Math.floor(val * factor));
};

window.closeGame = function () {
    fetch(`https://${GetParentResourceName()}/close`, { method: 'POST' });
    container.style.display = 'none';
};

window.addEventListener('message', (event) => {
    if (event.data.action === 'open') {
        container.style.display = 'flex';
        setBalance(event.data.balance);
        initBoard();
    }
});
document.onkeyup = function (data) { if (data.which == 27) closeGame(); };

initBoard();