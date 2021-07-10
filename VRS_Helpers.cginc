#ifndef VRS_HELPERS
#define VRS_HELPERS

float calcAlpha(float cutoff, float alpha, float mode)
{
    UNITY_BRANCH
    if(mode==1)
    {
        clip(alpha - cutoff);
        return alpha;
    }
    else return alpha;

}



#endif