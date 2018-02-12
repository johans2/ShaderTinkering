using System.Collections;
using System.Collections.Generic;
using UnityEngine;

[ExecuteInEditMode]
public class Rotate : MonoBehaviour {

    public float xSpeed = 1;
    public float ySpeed = 1;
    public float zSpeed = 1;
    
	void Update () {
        transform.Rotate(new Vector3(xSpeed, ySpeed, zSpeed) * Time.deltaTime);	
	}
}
