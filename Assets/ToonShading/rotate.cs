using System.Collections;
using System.Collections.Generic;
using UnityEngine;

public class rotate : MonoBehaviour {

    public Vector3 speed;

	void Update () {
        if (Input.GetKey(KeyCode.LeftArrow))
        {
            transform.Rotate(Time.deltaTime * -speed.x, Time.deltaTime * -speed.y, Time.deltaTime * -speed.z);
        }
        if (Input.GetKey(KeyCode.RightArrow))
        {
            transform.Rotate(Time.deltaTime * speed.x, Time.deltaTime * speed.y, Time.deltaTime * speed.z);
        }
    }
}
