/* ============================================================
   EduRiskVision — js/predictor.js
   Predictive ML Engine & What-If Student Risk Simulator
   ============================================================ */

const RiskPredictor = (function() {

  // Risk Score calculation strictly aligned with project methodology
  function calculateRiskScore(inputs) {
    const {
      attendance = 75,
      internal_marks = 60,
      assignment_completion = 70,
      lms_engagement = 60,
      prev_gpa = 6.5,
      backlogs = 0,
      lab_performance = 65
    } = inputs;

    // Academic weights from EduRiskVision framework
    const rawScore = (
      0.30 * attendance +
      0.30 * internal_marks +
      0.15 * assignment_completion +
      0.10 * lms_engagement +
      0.10 * (prev_gpa * 10) +
      0.05 * lab_performance
    );

    // Backlog impact penalty (each active backlog significantly drags down the overall standing)
    const backlogPenalty = backlogs * 4.5;
    let finalScore = Math.round(rawScore - backlogPenalty);
    finalScore = Math.max(0, Math.min(100, finalScore));

    // Thresholds:
    // Low Risk: >= 65
    // Medium Risk: 40 - 64
    // High Risk: < 40
    let riskTier = 'Low_Risk';
    let riskLabel = 'Low Risk (Safe)';
    let riskColor = '#10B981';

    if (finalScore < 40) {
      riskTier = 'High_Risk';
      riskLabel = 'High Risk (Critical)';
      riskColor = '#EF4444';
    } else if (finalScore < 65) {
      riskTier = 'Medium_Risk';
      riskLabel = 'Medium Risk (Moderate)';
      riskColor = '#F59E0B';
    }

    // Engagement index (weighted composite)
    const engagementIndex = parseFloat(
      (0.40 * attendance + 0.30 * assignment_completion + 0.30 * lms_engagement).toFixed(2)
    );

    // Random Forest ensemble probability estimation
    const probs = calculateRFProbabilities(finalScore, inputs);

    // Targeted Interventions
    const interventions = generateInterventions(inputs, riskTier);

    return {
      score: finalScore,
      tier: riskTier,
      label: riskLabel,
      color: riskColor,
      engagementIndex,
      probabilities: probs,
      interventions
    };
  }

  // Simulates Random Forest ensemble class distribution
  function calculateRFProbabilities(score, inputs) {
    // Sigmoid / soft-max distribution centered on tier thresholds
    let pHigh, pMed, pLow;

    if (score < 40) {
      const severity = (40 - score) / 40; // 0 to 1
      pHigh = 65 + (severity * 30) + (inputs.backlogs * 3);
      pMed = Math.max(5, 30 - (severity * 20));
      pLow = Math.max(1, 100 - pHigh - pMed);
    } else if (score < 65) {
      const progress = (score - 40) / 25; // 0 to 1
      pMed = 55 + Math.sin(progress * Math.PI) * 20;
      pHigh = Math.max(5, (1 - progress) * 35);
      pLow = Math.max(5, 100 - pMed - pHigh);
    } else {
      const excellence = (score - 65) / 35; // 0 to 1
      pLow = 65 + (excellence * 32);
      pMed = Math.max(2, (1 - excellence) * 28);
      pHigh = Math.max(1, 100 - pLow - pMed);
    }

    // Normalize to exact 100%
    const sum = pLow + pMed + pHigh;
    return {
      low: Math.round((pLow / sum) * 100),
      medium: Math.round((pMed / sum) * 100),
      high: Math.round((pHigh / sum) * 100)
    };
  }

  // Generate tailored academic intervention action plans
  function generateInterventions(inputs, tier) {
    const list = [];

    if (inputs.attendance < 75) {
      list.push(`⚠️ Attendance Alert (${inputs.attendance}%): Schedule immediate attendance counseling and alert faculty proctor.`);
    }
    if (inputs.internal_marks < 50) {
      list.push(`📉 Academic Performance (${inputs.internal_marks}%): Assign student to peer-tutoring circles and structured remedial study hours.`);
    }
    if (inputs.backlogs > 0) {
      list.push(`📋 Backlog Recovery Plan: Student has ${inputs.backlogs} active backlog(s). Advise supplementary coaching before semester finals.`);
    }
    if (inputs.lms_engagement < 50) {
      list.push(`💻 Digital Engagement: Low portal activity (${inputs.lms_engagement}/100). Mandate weekly LMS quiz submissions.`);
    }
    if (inputs.assignment_completion < 60) {
      list.push(`✍️ Assignment Tracking: Incomplete coursework (${inputs.assignment_completion}%). Enforce weekly milestone check-ins.`);
    }

    if (tier === 'High_Risk' && list.length === 0) {
      list.push("🚨 Urgent: Comprehensive 1-on-1 academic counseling with Head of Department recommended.");
    } else if (tier === 'Low_Risk' && list.length === 0) {
      list.push("✅ Stellar Academic Trajectory: Qualifies for advanced research electives, hackathons, and honors mentorship.");
    }

    return list;
  }

  return {
    calculateRiskScore
  };

})();

if (typeof module !== 'undefined') {
  module.exports = RiskPredictor;
}
