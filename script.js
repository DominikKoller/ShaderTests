import * as PIXI from 'pixi.js';
import html2canvas from 'html2canvas';
import vertexShaderSource from './vertexShader.glsl?raw';
import fragmentShaderSource from './fragmentShader.glsl?raw';

const effectDuration = 4.0;
const debug = false;

let activeApp; // Store the active app to destroy it later

document.getElementById("effect-button").onclick = () => {
    var message = document.querySelector(".message");

    activeApp?.canvas?.remove();
    activeApp?.destroy(true);

    html2canvas(message).then(canvas => {
        drawCanvasWithPixi(canvas, message);
    });
};

async function drawCanvasWithPixi(canvas, ontoElement) {
    // Initialize Pixi application using the new API
    const app = new PIXI.Application();
    activeApp = app;
    const devicePixelRatio = window.devicePixelRatio || 1;

    await app.init({
        width: ontoElement.offsetWidth,
        height: ontoElement.offsetHeight,
        resolution: devicePixelRatio,
        preference: 'webgl',
    });
    ontoElement.appendChild(app.canvas); // Update to use app.canvas instead of app.view

    app.canvas.style.width = `${ontoElement.offsetWidth}px`;
    app.canvas.style.height = `${ontoElement.offsetHeight}px`;

    // Create texture from the canvas
    const texture = PIXI.Texture.from(canvas, {
        resolution: devicePixelRatio
    });

    // Create a container to apply the shader
    let container = new PIXI.Container();
    app.stage.addChild(container);

    // Create a sprite to display your texture
    let sprite = new PIXI.Sprite(texture);
    sprite.scale.set(1 / devicePixelRatio);
    container.addChild(sprite);

    const invertFilter = new PIXI.Filter({
        glProgram: new PIXI.GlProgram({
            fragment: fragmentShaderSource,
            vertex: vertexShaderSource
        }),
        resources: {
            timeUniforms: {
                uTime: { value: 0.0, type: 'f32' },
                uProgress: { value: 0.0, type: 'f32'},
                uDebug: { value: debug ? 1 : 0, type: 'i32' },
            },
        },
    });
    sprite.filters = [invertFilter];

    app.ticker.add((ticker) =>
    {
        invertFilter.resources.timeUniforms.uniforms.uTime += 0.04 * ticker.deltaTime;
        invertFilter.resources.timeUniforms.uniforms.uProgress = Math.min(1.0, invertFilter.resources.timeUniforms.uniforms.uTime / effectDuration);
    });
}