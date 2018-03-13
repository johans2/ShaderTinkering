using System.Collections;
using System.Collections.Generic;
using UnityEngine;

public class GrassPhysics : MonoBehaviour {
    
    public Transform[] trampleTransforms;

    [Range(0.001f, 1f)]
    public float trampleCutoff = 0.1f;

    [Range(0.001f, 1f)]
    public float springiness = 0.01f;

    public Material grassMat;
    public ComputeShader shader;
    public Material debugMat;

    private int texWidth = 512;
    private int texHeight = 512;

    int updateKernel;
    private RenderTexture renderTex;
    private ComputeBuffer trampleBuffer;
    private ComputeBuffer tramplerObjectsBuffer;

    private Vector4[] tramplerData;
    private Vector2[] previousPos;

    void Start () {
        tramplerData = new Vector4[trampleTransforms.Length];
        previousPos = new Vector2[trampleTransforms.Length];
        
        // Create a rendertexture, for reading results.
        renderTex = new RenderTexture(512, 512, 24);
        renderTex.enableRandomWrite = true;
        renderTex.wrapMode = TextureWrapMode.Clamp;
        renderTex.Create();
        
        // Create the compute buffer, for storing previous values.
        Vector4[] bufferData = new Vector4[texWidth * texHeight];
        trampleBuffer = new ComputeBuffer(bufferData.Length, 16); // 16 is 4 bytes for 4 floats
        
        // Sets the texture and buffer for the update kernel.
        updateKernel = shader.FindKernel("UpdatePhysics");
        shader.SetTexture(updateKernel, "Result", renderTex);
        shader.SetBuffer(updateKernel, "trampleBuffer", trampleBuffer);
        shader.SetFloat("width", texWidth);
        shader.SetFloat("height", texHeight);
        shader.SetFloat("trampleCutoff", trampleCutoff);
        shader.SetFloat("springiness", springiness);
        
        // Set the result texture in the grass material.
        grassMat.SetTexture("_TrampleTex", renderTex);
        
        // Set the debug texture
        if (debugMat != null)
        {
            debugMat.SetTexture("_MainTex", renderTex);
        }
    }
	
	void Update () {

        for (int i = 0; i < trampleTransforms.Length; i++)
        {
            // These calculations are used to get the correct UV values from the world positions. 
            // Should be fixed later on.
            Vector2 tramplePos = new Vector2(trampleTransforms[i].position.x, trampleTransforms[i].position.z);
            tramplePos /= 100f;
            tramplePos.x += 0.50000000f;
            tramplePos.y += 0.50000000f;
            Vector2 moveDir = tramplePos - previousPos[i];
            
            tramplerData[i] = new Vector4(1f - tramplePos.x, 1f - tramplePos.y, moveDir.x, moveDir.y);
            previousPos[i] = tramplePos;
        }
        
        tramplerObjectsBuffer = new ComputeBuffer(tramplerData.Length, 16); // 16 is 4 bytes for 4 floats
        tramplerObjectsBuffer.SetData(tramplerData);
        shader.SetBuffer(updateKernel, "tramplerObjects", tramplerObjectsBuffer);

        shader.Dispatch(updateKernel, texWidth / 8, texHeight / 8, 1);

        
        tramplerObjectsBuffer.Dispose();
	}

    void OnDestroy() {
        trampleBuffer.Dispose();
    }
}
