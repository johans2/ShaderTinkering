using System.Collections;
using System.Collections.Generic;
using UnityEngine;

public class FireParticleSimulation : MonoBehaviour
{
    
    struct Particle
    {
        public Vector3 position;
        public Vector3 velocity;
        public float life;
        public Vector3 startPos;
        public Vector3 convergenceTarget;
    }

    struct MeshTriangle
    {
        public Vector3 vert1;
        public Vector3 vert2;
        public Vector3 vert3;
    }


    public MeshFilter meshFilter;
    public Transform emitterTrans;
    

    [Range(0.001f,1f)]
    public float curlE = 0.1f;

    [Range(0.001f, 0.3f)]
    public float curlMultiplier = 0.05f;

    [Range(0.0f, 10f)]
    public float particleMaxLife = 6.0f;

    [Range(0.0f, 10f)]
    public float particleMinLife = 2.0f;

    [Range(0.001f, 1f)]
    public float curlEmin = 0.1f;

    [Range(0.001f, 1f)]
    public float curlEmax = 0.3f;

    [Range(0.0f, 20f)]
    public float curlESpeed = 1f;

    [Range(0.001f, 0.1f)]
    public float sizeByLifeMin = 0.015f;

    [Range(0.001f, 0.1f)]
    public float sizeByLifeMax = 0.03f;

    public Vector3 convergencePoint = new Vector3(0, 2, 0);

    [Range(0.0f, 0.3f)]
    public float convergenceStrength = 0.01f;

    [Range(-0.3f, 0.3f)]
    public float updraft = 0.025f;

    /// <summary>
    /// Material used to draw the Particle on screen.
    /// </summary>
    public Material material;

    /// <summary>
    /// Compute shader used to update the Particles.
    /// </summary>
    public ComputeShader computeShader;

    public Transform emitterTransform;

    /// <summary>
    /// Size in octet of the Particle struct.
    /// Vector3 position            = 12 bytes
    /// Vector3 velocity            = 12 bytes
    /// float   life                = 4 bytes
    /// Vector3 startPos            = 12 bytes
    /// Vector3 convergenceTarget   = 12 bytes
    ///                             ----------
    /// TOTAL                       = 52 bytes
    /// </summary>
    private const int SIZE_PARTICLE = 52;

    /// <summary>
    /// Number of Particle created in the system.
    /// </summary>
    private int particleCount = 3000000;
    /// <summary>
    /// Id of the kernel used.
    /// </summary>
    private int mComputeShaderKernelID;

    /// <summary>
    /// Buffer holding the Particles.
    /// </summary>
    ComputeBuffer particleBuffer;

    /// <summary>
    /// Number of particle per warp.
    /// </summary>
    private const int WARP_SIZE = 256; // TODO?

    /// <summary>
    /// Number of warp needed.
    /// </summary>
    private int mWarpCount; // TODO?

    /// <summary>
    /// temporary list for storing mesh verts.
    /// </summary>
    private List<Vector3> verts = new List<Vector3>();


    /// <summary>
    /// Compute buffer used for storing mesh triangles.
    /// </summary>
    private ComputeBuffer meshBuffer;


    private const float away = 99999999.0f;

    // Use this for initialization
    void Start()
    {
        
        InitComputeShader();

    }

    void UpdateCurlE() {
        curlE = Mathf.Lerp(curlEmin, curlEmax, Mathf.Sin(Time.timeSinceLevelLoad * curlESpeed) / 2.0f + 0.5f);
    }

    void InitComputeShader()
    {
        mWarpCount = Mathf.CeilToInt((float)particleCount / WARP_SIZE);

        // initialize the particles
        Particle[] particleArray = new Particle[particleCount];

        for (int i = 0; i < particleCount; i++)
        {
            particleArray[i].position.x = away;
            particleArray[i].position.y = away;
            particleArray[i].position.z = away;

            particleArray[i].velocity.x = 0;
            particleArray[i].velocity.y = 0;
            particleArray[i].velocity.z = 0;

            // Initial life value
            particleArray[i].life = Random.value * 5.0f + 1.0f;
        }

        // find the id of the kernel
        mComputeShaderKernelID = computeShader.FindKernel("UpdateParticles");


        // Get the mesh buffer into the compute shader
        MeshTriangle[] meshVerts = GetMeshTriangles();
        meshBuffer = new ComputeBuffer(meshVerts.Length, 36);
        meshBuffer.SetData(meshVerts);
        computeShader.SetBuffer(mComputeShaderKernelID, "meshBuffer", meshBuffer);

        computeShader.SetInt("numVertices", meshVerts.Length);
        computeShader.SetFloat("particleMinLife", particleMinLife);
        computeShader.SetFloat("particleMaxLife", particleMaxLife);
        computeShader.SetFloats("convergencePoint", new float[] { convergencePoint.x, convergencePoint.y, convergencePoint.z } );
        computeShader.SetFloat("convergenceStrength", convergenceStrength);
        computeShader.SetFloat("updraft", updraft);

        // create compute buffer
        particleBuffer = new ComputeBuffer(particleCount, SIZE_PARTICLE);
        
        particleBuffer.SetData(particleArray);


        // bind the compute buffer to the shader and the compute shader
        computeShader.SetBuffer(mComputeShaderKernelID, "particleBuffer", particleBuffer);
        material.SetBuffer("particleBuffer", particleBuffer);
        material.SetFloat("_SizeByLifeMin", sizeByLifeMin);
        material.SetFloat("_SizeByLifeMax", sizeByLifeMax);
    }

    void OnRenderObject()
    {
        material.SetPass(0);
        Graphics.DrawProcedural(MeshTopology.Points, 1, particleCount);
    }
    
    void OnDestroy()
    {
        if (particleBuffer != null)
            particleBuffer.Release();
        if (meshBuffer != null)
            meshBuffer.Release();
    }
    
    void Update()
    {
        UpdateCurlE();


        float[] emitterPosition = { emitterTransform.position.x, emitterTransform.position.y, emitterTransform.position.z };
        float[] emitterScale = { emitterTransform.localScale.x, emitterTransform.localScale.y, emitterTransform.localScale.z };
        float[] emitterRot = { emitterTransform.rotation.eulerAngles.x, emitterTransform.rotation.eulerAngles.y, emitterTransform.rotation.eulerAngles.z };
        // Send datas to the compute shader
        computeShader.SetFloat("deltaTime", Time.deltaTime);
        computeShader.SetFloat("curlE", curlE);
        computeShader.SetFloat("curlMultiplier", curlMultiplier);
        computeShader.SetFloat("particleMinLife", particleMinLife);
        computeShader.SetFloat("particleMaxLife", particleMaxLife);
        computeShader.SetFloats("emitterPos", emitterPosition);
        computeShader.SetFloats("emitterScale", emitterScale);
        computeShader.SetFloats("emitterRot", emitterRot);
        computeShader.SetFloat("randSeed", Random.Range(0.0f, verts.Count));
        computeShader.SetFloats("convergencePoint", new float[] { convergencePoint.x, convergencePoint.y, convergencePoint.z });
        computeShader.SetFloat("convergenceStrength", convergenceStrength);
        computeShader.SetFloat("updraft", updraft);

        material.SetFloat("_SizeByLifeMin", sizeByLifeMin);
        material.SetFloat("_SizeByLifeMax", sizeByLifeMax);

        // Update the Particles
        computeShader.Dispatch(mComputeShaderKernelID, mWarpCount, 1, 1);
    }
    
    private MeshTriangle[] GetMeshTriangles() {

        List<MeshTriangle> triangles = new List<MeshTriangle>();


        meshFilter.mesh.GetVertices(verts);


        int[] triangelIndices = meshFilter.mesh.GetTriangles(0);
        Debug.Log("tris: " + triangelIndices.Length);
        Debug.Log("verts: " + verts.Count);
        
        for (int i = 0; i < triangelIndices.Length; i += 3)
        {
            MeshTriangle triangle = new MeshTriangle
            {
                vert1 = verts[triangelIndices[i]],
                vert2 = verts[triangelIndices[i + 1]],
                vert3 = verts[triangelIndices[i + 2]]
            };

            triangles.Add(triangle);
        }

        Debug.Log(triangles.Count + " triangels added.");


        return triangles.ToArray();

    }

    void OnDrawGizmosSelected() {
        Gizmos.DrawSphere(emitterTrans.position + convergencePoint, .1f);
    }

}

