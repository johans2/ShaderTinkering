using System.Collections;
using System.Collections.Generic;
using UnityEngine;

public class rotate : MonoBehaviour {

    public Vector3 speed;

	void Update () {
        transform.Rotate(Time.deltaTime * speed.x, Time.deltaTime * speed.y, Time.deltaTime * speed.z);
	}
}
