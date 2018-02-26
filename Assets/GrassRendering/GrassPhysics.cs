using System.Collections;
using System.Collections.Generic;
using UnityEngine;

public class GrassPhysics : MonoBehaviour {
    
    public Transform trampleTransform;
    public float trampleSmooth = 2f;
    public float trampleCutoff = 0.1f;

    public Material grassMat;
    public ComputeShader shader;
    public Material debugMat;


    int updateKernel;
    private RenderTexture renderTex;

    void Start () {
        int flashInputHandler = shader.FindKernel("FlashInput");
        updateKernel = shader.FindKernel("UpdatePhysics");

        renderTex = new RenderTexture(512, 512, 24);
        renderTex.enableRandomWrite = true;
        renderTex.wrapMode = TextureWrapMode.Clamp;
        
        renderTex.Create();

        shader.SetTexture(flashInputHandler, "Result", renderTex);
        shader.Dispatch(flashInputHandler, 512 / 8, 512 / 8, 1);
        shader.SetTexture(updateKernel, "Result", renderTex);
        shader.SetFloat("width", 512);
        shader.SetFloat("height", 512);
        shader.SetFloat("trampleSmooth", trampleSmooth);
        shader.SetFloat("trampleCutoff", trampleCutoff);

        grassMat.SetTexture("_TrampleTex", renderTex);

        if (debugMat != null)
        {
            debugMat.SetTexture("_MainTex", renderTex);
        }
    }
	
	void Update () {

        // These calculations are used to get the correct UV values from the world positions. 
        // Should be fixed later on.
        Vector4 tramplePos = (trampleTransform.position / 100f);
        tramplePos.x += 0.5000000f;
        tramplePos.z += 0.5000000f;       
        shader.SetVector("tramplePos", new Vector4(1 - tramplePos.x, tramplePos.y, 1 - tramplePos.z, 0));

        Debug.Log(tramplePos.x + "   " + tramplePos.z);

        shader.Dispatch(updateKernel, 512 / 8, 512 / 8, 1);


	}
}
