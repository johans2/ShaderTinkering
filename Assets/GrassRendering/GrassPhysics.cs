using System.Collections;
using System.Collections.Generic;
using UnityEngine;

public class GrassPhysics : MonoBehaviour {


    public Transform trampleTransform;

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
        renderTex.Create();

        shader.SetTexture(flashInputHandler, "Result", renderTex);
        shader.Dispatch(flashInputHandler, 512 / 8, 512 / 8, 1);
        shader.SetTexture(updateKernel, "Result", renderTex);
        grassMat.SetTexture("_TrampleTex", renderTex);

        if (debugMat != null)
        {
            debugMat.SetTexture("_MainTex", renderTex);
        }
    }
	
	void Update () {
        shader.SetFloat("eTime", Time.timeSinceLevelLoad);
        
        shader.Dispatch(updateKernel, 512 / 8, 512 / 8, 1);
	}
}
