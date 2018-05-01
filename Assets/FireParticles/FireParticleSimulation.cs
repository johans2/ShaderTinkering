using System.Collections;
using System.Collections.Generic;
using UnityEngine;

public class FireParticleSimulation : MonoBehaviour
{
    
    // struct
    struct Particle
    {
        public Vector3 position;
        public Vector3 velocity;
        public float life;
    }

    struct MeshTriangle
    {
        public Vector3 vert1;
        public Vector3 vert2;
        public Vector3 vert3;
    }


    public MeshFilter meshFilter;
    public Transform emitterTrans;
    List<Vector3> verts = new List<Vector3>();
    ComputeBuffer meshBuffer;

    [Range(0.001f,1f)]
    public float curlE = 0.1f;

    [Range(0.001f, 0.3f)]
    public float curlMultiplier = 0.05f;


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
    /// since float = 4 bytes...
    /// 4 floats = 16 bytes
	/// </summary>
	//private const int SIZE_PARTICLE = 24;
    private const int SIZE_PARTICLE = 28; // since property "life" is added...

    /// <summary>
    /// Number of Particle created in the system.
    /// </summary>
    private int particleCount = 1000000;
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
    
    // Use this for initialization
    void Start()
    {
        
        InitComputeShader();

    }


    void InitComputeShader()
    {
        mWarpCount = Mathf.CeilToInt((float)particleCount / WARP_SIZE);

        // initialize the particles
        Particle[] particleArray = new Particle[particleCount];

        for (int i = 0; i < particleCount; i++)
        {
            float x = Random.value * 2 - 1.0f;
            float y = Random.value * 2 - 1.0f;
            float z = Random.value * 2 - 1.0f;
            Vector3 xyz = new Vector3(x, y, z);
            xyz.Normalize();
            xyz *= Random.value;
            xyz *= 0.5f;


            particleArray[i].position.x = xyz.x;
            particleArray[i].position.y = xyz.y;
            particleArray[i].position.z = xyz.z + 3;

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

        // create compute buffer
        particleBuffer = new ComputeBuffer(particleCount, SIZE_PARTICLE);
        
        particleBuffer.SetData(particleArray);


        // bind the compute buffer to the shader and the compute shader
        computeShader.SetBuffer(mComputeShaderKernelID, "particleBuffer", particleBuffer);
        material.SetBuffer("particleBuffer", particleBuffer);
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

        float[] emitterPosition = { emitterTransform.position.x, emitterTransform.position.y, emitterTransform.position.z };

        // Send datas to the compute shader
        computeShader.SetFloat("deltaTime", Time.deltaTime);
        computeShader.SetFloat("curlE", curlE);
        computeShader.SetFloat("curlMultiplier", curlMultiplier);
        computeShader.SetFloats("emitterPos", emitterPosition);
        computeShader.SetFloat("randSeed", Random.Range(0.0f, verts.Count));
        
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
        for (int i = 0; i < verts.Count; i++)
        {
            Vector3 pos = verts[i];
            pos.x *= emitterTrans.localScale.x;
            pos.y *= emitterTrans.localScale.y;
            pos.z *= emitterTrans.localScale.z;
            
            pos += emitterTrans.position;
            

            // Rotation?



            //Gizmos.DrawSphere(pos, .1f);

        }

    }

}

