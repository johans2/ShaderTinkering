using System.Collections;
using System.Collections.Generic;
using UnityEngine;

public class FireMover : MonoBehaviour {

	public float moveSpeed = 10f;

	void Update () {

		if(Input.GetKey(KeyCode.UpArrow) ){
			transform.position += new Vector3(0,moveSpeed * Time.deltaTime, 0);
		}
		if(Input.GetKey(KeyCode.DownArrow) ){
			transform.position += new Vector3(0,-moveSpeed * Time.deltaTime, 0);
		}
		if(Input.GetKey(KeyCode.RightArrow) ){
			transform.position += new Vector3(moveSpeed * Time.deltaTime, 0, 0);
		}
		if(Input.GetKey(KeyCode.LeftArrow) ){
			transform.position += new Vector3(-moveSpeed * Time.deltaTime, 0, 0);
		}
	}
}
