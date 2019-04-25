using System.Collections;
using System.Collections.Generic;
using UnityEngine;

public class Pathtracer : MonoBehaviour
{
    [Range(0, 100)]
    public int numTraces;

    [Range(0, 200)]
    public int numTraceSteps;

    [Range(0, 10)]
    public float stepDistance;

    [Range(0, 10)]
    public float traceSpacing;

    [Range(0.1f, 5)]
    public float spaceDistortion = 1; // TODO: rename this.

    public GameObject traceObjectPrefab;
    public Transform traceContainer;
    public Transform cameraTransform;
    public GameObject blackHole;

    private List<Trace> traces = new List<Trace>();

    struct Trace {
        public List<Transform> traceObjects;
        public Vector3 startPosition;
    }

    void Start()
    {
        Vector3 startPosition = cameraTransform.position - Vector3.up * numTraces * traceSpacing / 2;

        for (int i = 0; i < numTraces; i++)
        {
            traces.Add(CreateTrace(startPosition + Vector3.up * traceSpacing * i));
        }
    }

    private void Update()
    {
        for (int i = 0; i < traces.Count; i++)
        {
            Trace trace = traces[i];
            bool continueTrace = true;
            Vector3 previousPos = cameraTransform.position + trace.startPosition;
            for (int j = 0; j < trace.traceObjects.Count; j++)
            {
                if (!continueTrace)
                {
                    break;
                }

                Vector3 unaffectedAddVector = Vector3.forward * stepDistance;
                Vector3 maxAffectedAddVector = (blackHole.transform.position - previousPos).normalized * stepDistance; // Pointing straight towards the black hole. 
                
                Vector3 addVector = unaffectedAddVector;

                // TODO: Dont use this if statement. Have the addvector lerp by a curve value instead. f(x) = (R^p) / x^p where p is gravitational "pull". 
                if((blackHole.transform.position - previousPos).magnitude < (0.5f * 2.6f)) {
                    addVector = maxAffectedAddVector;
                    trace.traceObjects[j].GetComponent<Renderer>().material.color = Color.blue;
                }

                float distanceToSingularity = Vector3.Distance(blackHole.transform.position, previousPos);
                float lerpValue = GetSpaceDistortionLerpValue(0.5f, distanceToSingularity, spaceDistortion);
                addVector = Vector3.Lerp(unaffectedAddVector, maxAffectedAddVector, lerpValue).normalized * stepDistance;

                //Debug.DrawLine(previousPos, previousPos + addVector, Color.red);

                Transform pathObjectTransform = trace.traceObjects[j];
                pathObjectTransform.position = previousPos + addVector;
                previousPos = pathObjectTransform.position;

                // Inside black hole. Radius = 0.5 * scale.
                if (Vector3.Distance(pathObjectTransform.position, blackHole.transform.position) < (blackHole.transform.localScale.x * 0.5))
                {
                    pathObjectTransform.gameObject.SetActive(false);
                    //continueTrace = false;
                }
                else {
                    pathObjectTransform.gameObject.SetActive(true);
                }


            }
        }
    }

    private float GetSpaceDistortionLerpValue(float schwarzschildRadius, float distanceToSingularity, float spaceDistortion) {
        return Mathf.Pow(schwarzschildRadius, spaceDistortion) / Mathf.Pow(distanceToSingularity, spaceDistortion);
    }

    private Trace CreateTrace(Vector3 startPosition) {
        Trace t = new Trace();
        t.traceObjects = new List<Transform>();
        t.startPosition = startPosition;

        for (int i = 0; i < numTraceSteps; i++)
        {
            GameObject traceObject = Instantiate(traceObjectPrefab, Vector3.zero, Quaternion.identity);
            traceObject.transform.parent = traceContainer;
            t.traceObjects.Add(traceObject.transform);
        }

        return t;
    }


}
