using System.Collections;
using System.Collections.Generic;
using UnityEngine;

public class GrassPhysics : MonoBehaviour {
    
    public Transform trampleTransform;

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
    private ComputeBuffer imgBuffer;
    private Vector2 previousPos;

    void Start () {
        // Create a rendertexture, for reading results.
        renderTex = new RenderTexture(512, 512, 24);
        renderTex.enableRandomWrite = true;
        renderTex.wrapMode = TextureWrapMode.Clamp;
        renderTex.Create();
        
        // Create the compute buffer, for storing previous values.
        Vector4[] bufferData = new Vector4[texWidth * texHeight];
        imgBuffer = new ComputeBuffer(bufferData.Length, 16); // 16 is 4 bytes for 4 floats
        
        // Sets the texture and buffer for the update kernel.
        updateKernel = shader.FindKernel("UpdatePhysics");
        shader.SetTexture(updateKernel, "Result", renderTex);
        shader.SetBuffer(updateKernel, "imgBuffer", imgBuffer);
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

        // These calculations are used to get the correct UV values from the world positions. 
        // Should be fixed later on.
        Vector2 tramplePos = new Vector2(trampleTransform.position.x, trampleTransform.position.z);
        tramplePos /= 100f;
        tramplePos.x += 0.50000000f;
        tramplePos.y += 0.50000000f;
        Vector2 moveDir = tramplePos - previousPos;
        float velocity = Vector3.Magnitude(moveDir);
        
        // Update the trample position and the move direction.
        shader.SetVector("tramplePos", new Vector2(1 - tramplePos.x, 1 - tramplePos.y));
        shader.SetVector("moveDir", new Vector2(moveDir.x, moveDir.y));

        shader.Dispatch(updateKernel, texWidth / 8, texHeight / 8, 1);

        previousPos = tramplePos;
	}

    void OnDestroy() {
        imgBuffer.Dispose();
    }
}
