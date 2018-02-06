using System.Collections;
using System.Collections.Generic;
using UnityEngine;

[ExecuteInEditMode]
public class GrassPointCloudRenderer : MonoBehaviour {

    public MeshFilter filter;
    private Mesh mesh;

    public int seed;
    public Vector2 size;

    [Range(0,60000)]
    public int grassNumber;

    public float startHeight = 1000f;
    public float grassOffset = 0.0f;

    private Vector3 lastPosition = new Vector3(999999,99999,99999);

	void Update () {
        if (lastPosition != transform.position)
        {
            Random.InitState(seed);

            List<Vector3> positions = new List<Vector3>(grassNumber);
            int[] indicies = new int[grassNumber];
            List<Color> colors = new List<Color>(grassNumber);
            List<Vector3> normals = new List<Vector3>(grassNumber);

            for (int i = 0; i < grassNumber; ++i)
            {
                Vector3 origin = transform.position;
                origin.y = startHeight;
                origin.x += size.x * Random.Range(-0.5f, 0.5f);
                origin.z += size.y * Random.Range(-0.5f, 0.5f);
                Ray ray = new Ray(origin, Vector3.down);
                RaycastHit hit;

                if (Physics.Raycast(ray, out hit))
                {
                    origin = hit.point;
                    origin.y = grassOffset;

                    positions.Add(origin);
                    indicies[i] = i;
                    colors.Add(new Color(Random.Range(0.0f, 1.0f), Random.Range(0.0f, 1.0f), Random.Range(0.0f, 1.0f), 1));
                    normals.Add(hit.normal);
                }


            }

            mesh = new Mesh();
            mesh.SetVertices(positions);
            mesh.SetIndices(indicies, MeshTopology.Points, 0);
            mesh.SetColors(colors);
            mesh.SetNormals(normals);
            filter.mesh = mesh;

            lastPosition = transform.position;
        }
        
        	
	}
}
